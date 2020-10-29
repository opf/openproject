# frozen_string_literal: true

require 'stringio'

module PDF
  module Core
    class Renderer
      def initialize(state)
        @state = state
        @state.populate_pages_from_store(self)

        min_version(state.store.min_version) if state.store.min_version

        @page_number = 0
      end

      attr_reader :state

      # Creates a new Reference and adds it to the Document's object list.  The
      # +data+ argument is anything that Prawn.pdf_object() can convert.
      #
      # Returns the identifier which points to the reference in the ObjectStore
      #
      def ref(data)
        ref!(data).identifier
      end

      # Like ref, but returns the actual reference instead of its identifier.
      #
      # While you can use this to build up nested references within the object
      # tree, it is recommended to persist only identifiers, and then provide
      # helper methods to look up the actual references in the ObjectStore
      # if needed.  If you take this approach, Document::Snapshot
      # will probably work with your extension
      #
      def ref!(data)
        state.store.ref(data)
      end

      # At any stage in the object tree an object can be replaced with an
      # indirect reference. To get access to the object safely, regardless
      # of if it's hidden behind a Prawn::Reference, wrap it in deref().
      #
      def deref(obj)
        obj.is_a?(PDF::Core::Reference) ? obj.data : obj
      end

      # Appends a raw string to the current page content.
      #
      #  # Raw line drawing example:
      #  x1,y1,x2,y2 = 100,500,300,550
      #
      #  pdf.add_content("#{PDF::Core.real_params([x1, y1])} m")   # move
      #  pdf.add_content("#{PDF::Core.real_params([ x2, y2 ])} l") # draw path
      #  pdf.add_content('S') # stroke
      #
      def add_content(str)
        save_graphics_state if graphic_state.nil?
        state.page.content << str << "\n"
      end

      # The Name dictionary (PDF spec 3.6.3) for this document. It is
      # lazily initialized, so that documents that do not need a name
      # dictionary do not incur the additional overhead.
      #
      def names
        state.store.root.data[:Names] ||= ref!(Type: :Names)
      end

      # Returns true if the Names dictionary is in use for this document.
      #
      def names?
        state.store.root.data[:Names]
      end

      # Defines a block to be called just before the document is rendered.
      #
      def before_render(&block)
        state.before_render_callbacks << block
      end

      # Defines a block to be called just before a new page is started.
      #
      def on_page_create(&block)
        state.on_page_create_callback =
          if block_given?
            block
          end
      end

      def start_new_page(options = {})
        last_page = state.page
        if last_page
          last_page_size    = last_page.size
          last_page_layout  = last_page.layout
          last_page_margins = last_page.margins
        end

        page_options = {
          size: options[:size] || last_page_size,
          layout: options[:layout] || last_page_layout,
          margins: last_page_margins
        }
        if last_page
          if last_page.graphic_state
            new_graphic_state = last_page.graphic_state.dup
          end

          # Erase the color space so that it gets reset on new page for fussy
          # pdf-readers
          if new_graphic_state
            new_graphic_state.color_space = {}
          end
          page_options[:graphic_state] = new_graphic_state
        end

        state.page = PDF::Core::Page.new(self, page_options)

        state.insert_page(state.page, @page_number)
        @page_number += 1

        state.on_page_create_action(self)
      end

      def page_count
        state.page_count
      end

      # Re-opens the page with the given (1-based) page number so that you can
      # draw on it.
      #
      # See Prawn::Document#number_pages for a sample usage of this capability.

      def go_to_page(page_number)
        @page_number = page_number
        state.page = state.pages[page_number - 1]
      end

      def finalize_all_page_contents
        (1..page_count).each do |i|
          go_to_page i
          while graphic_stack.present?
            restore_graphics_state
          end
          state.page.finalize
        end
      end

      # raise the PDF version of the file we're going to generate.
      # A private method, designed for internal use when the user adds a feature
      # to their document that requires a particular version.
      #
      def min_version(min)
        state.version = min if min > state.version
      end

      # Renders the PDF document to string.
      # Pass an open file descriptor to render to file.
      #
      def render(output = StringIO.new)
        if output.instance_of?(StringIO)
          output.set_encoding(::Encoding::ASCII_8BIT)
        end
        finalize_all_page_contents

        render_header(output)
        render_body(output)
        render_xref(output)
        render_trailer(output)
        if output.instance_of?(StringIO)
          str = output.string
          str.force_encoding(::Encoding::ASCII_8BIT)
          return str
        else
          return nil
        end
      end

      # Renders the PDF document to file.
      #
      #   pdf.render_file 'foo.pdf'
      #
      def render_file(filename)
        File.open(filename, 'wb') { |f| render(f) }
      end

      # Write out the PDF Header, as per spec 3.4.1
      #
      def render_header(output)
        state.before_render_actions(self)

        # pdf version
        output << "%PDF-#{state.version}\n"

        # 4 binary chars, as recommended by the spec
        output << "%\xFF\xFF\xFF\xFF\n"
      end

      # Write out the PDF Body, as per spec 3.4.2
      #
      def render_body(output)
        state.render_body(output)
      end

      # Write out the PDF Cross Reference Table, as per spec 3.4.3
      #
      def render_xref(output)
        @xref_offset = output.size
        output << "xref\n"
        output << "0 #{state.store.size + 1}\n"
        output << "0000000000 65535 f \n"
        state.store.each do |ref|
          output.printf('%010d', ref.offset)
          output << " 00000 n \n"
        end
      end

      # Write out the PDF Trailer, as per spec 3.4.4
      #
      def render_trailer(output)
        trailer_hash = {
          Size: state.store.size + 1,
          Root: state.store.root,
          Info: state.store.info
        }
        trailer_hash.merge!(state.trailer) if state.trailer

        output << "trailer\n"
        output << PDF::Core.pdf_object(trailer_hash) << "\n"
        output << "startxref\n"
        output << @xref_offset << "\n"
        output << '%%EOF' << "\n"
      end

      def open_graphics_state
        add_content 'q'
      end

      def close_graphics_state
        add_content 'Q'
      end

      def save_graphics_state(graphic_state = nil)
        graphic_stack.save_graphic_state(graphic_state)
        open_graphics_state
        if block_given?
          yield
          restore_graphics_state
        end
      end

      # Returns true if content streams will be compressed before rendering,
      # false otherwise
      #
      def compression_enabled?
        state.compress
      end

      # Pops the last saved graphics state off the graphics state stack and
      # restores the state to those values
      def restore_graphics_state
        if graphic_stack.empty?
          raise PDF::Core::Errors::EmptyGraphicStateStack,
            "\n You have reached the end of the graphic state stack"
        end
        close_graphics_state
        graphic_stack.restore_graphic_state
      end

      def graphic_stack
        state.page.stack
      end

      def graphic_state
        save_graphics_state unless graphic_stack.current_state
        graphic_stack.current_state
      end
    end
  end
end

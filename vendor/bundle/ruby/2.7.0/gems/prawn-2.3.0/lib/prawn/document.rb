# frozen_string_literal: true

# document.rb : Implements PDF document generation for Prawn
#
# Copyright April 2008, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'stringio'

require_relative 'document/bounding_box'
require_relative 'document/column_box'
require_relative 'document/internals'
require_relative 'document/span'

module Prawn
  # The Prawn::Document class is how you start creating a PDF document.
  #
  # There are three basic ways you can instantiate PDF Documents in Prawn, they
  # are through assignment, implicit block or explicit block.  Below is an
  # example of each type, each example does exactly the same thing, makes a PDF
  # document with all the defaults and puts in the default font "Hello There"
  # and then saves it to the current directory as "example.pdf"
  #
  # For example, assignment can be like this:
  #
  #   pdf = Prawn::Document.new
  #   pdf.text "Hello There"
  #   pdf.render_file "example.pdf"
  #
  # Or you can do an implied block form:
  #
  #   Prawn::Document.generate "example.pdf" do
  #     text "Hello There"
  #   end
  #
  # Or if you need to access a variable outside the scope of the block, the
  # explicit block form:
  #
  #   words = "Hello There"
  #   Prawn::Document.generate "example.pdf" do |pdf|
  #     pdf.text words
  #   end
  #
  # Usually, the block forms are used when you are simply creating a PDF
  # document that you want to immediately save or render out.
  #
  # See the new and generate methods for further details on the above.
  #
  class Document
    include Prawn::Document::Internals
    include PDF::Core::Annotations
    include PDF::Core::Destinations
    include Prawn::Document::Security
    include Prawn::Text
    include Prawn::Graphics
    include Prawn::Images
    include Prawn::Stamp
    include Prawn::SoftMask
    include Prawn::TransformationStack

    # @group Extension API

    # NOTE: We probably need to rethink the options validation system, but this
    # constant temporarily allows for extensions to modify the list.

    VALID_OPTIONS = %i[
      page_size page_layout margin left_margin
      right_margin top_margin bottom_margin skip_page_creation
      compress background info
      text_formatter print_scaling
    ].freeze

    # Any module added to this array will be included into instances of
    # Prawn::Document at the per-object level.  These will also be inherited by
    # any subclasses.
    #
    # Example:
    #
    #   module MyFancyModule
    #
    #     def party!
    #       text "It's a big party!"
    #     end
    #
    #   end
    #
    #   Prawn::Document.extensions << MyFancyModule
    #
    #   Prawn::Document.generate("foo.pdf") do
    #     party!
    #   end
    #
    #
    def self.extensions
      @extensions ||= []
    end

    # @private
    def self.inherited(base)
      extensions.each { |e| base.extensions << e }
    end

    # @group Stable Attributes

    attr_accessor :margin_box
    attr_reader :margins, :y
    attr_accessor :page_number

    # @group Extension Attributes

    attr_accessor :text_formatter

    # @group Stable API

    # Creates and renders a PDF document.
    #
    # When using the implicit block form, Prawn will evaluate the block
    # within an instance of Prawn::Document, simplifying your syntax.
    # However, please note that you will not be able to reference variables
    # from the enclosing scope within this block.
    #
    #   # Using implicit block form and rendering to a file
    #   Prawn::Document.generate "example.pdf" do
    #     # self here is set to the newly instantiated Prawn::Document
    #     # and so any variables in the outside scope are unavailable
    #     font "Times-Roman"
    #     draw_text "Hello World", :at => [200,720], :size => 32
    #   end
    #
    # If you need to access your local and instance variables, use the explicit
    # block form shown below.  In this case, Prawn yields an instance of
    # PDF::Document and the block is an ordinary closure:
    #
    #   # Using explicit block form and rendering to a file
    #   content = "Hello World"
    #   Prawn::Document.generate "example.pdf" do |pdf|
    #     # self here is left alone
    #     pdf.font "Times-Roman"
    #     pdf.draw_text content, :at => [200,720], :size => 32
    #   end
    #
    def self.generate(filename, options = {}, &block)
      pdf = new(options, &block)
      pdf.render_file(filename)
    end

    # Creates a new PDF Document.  The following options are available (with
    # the default values marked in [])
    #
    # <tt>:page_size</tt>:: One of the PDF::Core::PageGeometry sizes [LETTER]
    # <tt>:page_layout</tt>:: Either <tt>:portrait</tt> or <tt>:landscape</tt>
    # <tt>:margin</tt>:: Sets the margin on all sides in points [0.5 inch]
    # <tt>:left_margin</tt>:: Sets the left margin in points [0.5 inch]
    # <tt>:right_margin</tt>:: Sets the right margin in points [0.5 inch]
    # <tt>:top_margin</tt>:: Sets the top margin in points [0.5 inch]
    # <tt>:bottom_margin</tt>:: Sets the bottom margin in points [0.5 inch]
    # <tt>:skip_page_creation</tt>:: Creates a document without starting the
    #                                first page [false]
    # <tt>:compress</tt>:: Compresses content streams before rendering them
    #                      [false]
    # <tt>:background</tt>:: An image path to be used as background on all pages
    #                        [nil]
    # <tt>:background_scale</tt>:: Backgound image scale [1] [nil]
    # <tt>:info</tt>:: Generic hash allowing for custom metadata properties
    #                  [nil]
    # <tt>:text_formatter</tt>: The text formatter to use for
    #                           <tt>:inline_format</tt>ted text
    #                           [Prawn::Text::Formatted::Parser]
    #
    # Setting e.g. the :margin to 100 points and the :left_margin to 50 will
    # result in margins of 100 points on every side except for the left, where
    # it will be 50.
    #
    # The :margin can also be an array much like CSS shorthand:
    #
    #   # Top and bottom are 20, left and right are 100.
    #   :margin => [20, 100]
    #   # Top is 50, left and right are 100, bottom is 20.
    #   :margin => [50, 100, 20]
    #   # Top is 10, right is 20, bottom is 30, left is 40.
    #   :margin => [10, 20, 30, 40]
    #
    # Additionally, :page_size can be specified as a simple two value array
    # giving the width and height of the document you need in PDF Points.
    #
    # Usage:
    #
    #   # New document, US Letter paper, portrait orientation
    #   pdf = Prawn::Document.new
    #
    #   # New document, A4 paper, landscaped
    #   pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape)
    #
    #   # New document, Custom size
    #   pdf = Prawn::Document.new(page_size: [200, 300])
    #
    #   # New document, with background
    #   pdf = Prawn::Document.new(
    #     background: "#{Prawn::DATADIR}/images/pigs.jpg"
    #   )
    #
    def initialize(options = {}, &block)
      options = options.dup

      Prawn.verify_options VALID_OPTIONS, options

      # need to fix, as the refactoring breaks this
      # raise NotImplementedError if options[:skip_page_creation]

      self.class.extensions.reverse_each { |e| extend e }
      self.state = PDF::Core::DocumentState.new(options)
      state.populate_pages_from_store(self)
      renderer.min_version(state.store.min_version) if state.store.min_version

      renderer.min_version(1.6) if options[:print_scaling] == :none

      @background = options[:background]
      @background_scale = options[:background_scale] || 1
      @font_size = 12

      @bounding_box = nil
      @margin_box = nil

      @page_number = 0

      @text_formatter = options.delete(:text_formatter) ||
        Text::Formatted::Parser

      options[:size] = options.delete(:page_size)
      options[:layout] = options.delete(:page_layout)

      initialize_first_page(options)

      @bounding_box = @margin_box

      if block
        block.arity < 1 ? instance_eval(&block) : block[self]
      end
    end

    # @group Stable API

    # Creates and advances to a new page in the document.
    #
    # Page size, margins, and layout can also be set when generating a
    # new page. These values will become the new defaults for page creation
    #
    #   pdf.start_new_page #=> Starts new page keeping current values
    #   pdf.start_new_page(:size => "LEGAL", :layout => :landscape)
    #   pdf.start_new_page(:left_margin => 50, :right_margin => 50)
    #   pdf.start_new_page(:margin => 100)
    #
    def start_new_page(options = {})
      last_page = state.page
      if last_page
        last_page_size = last_page.size
        last_page_layout = last_page.layout
        last_page_margins = last_page.margins.dup
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

        # erase the color space so that it gets reset on new page for fussy
        # pdf-readers
        new_graphic_state&.color_space = {}

        page_options[:graphic_state] = new_graphic_state
      end

      state.page = PDF::Core::Page.new(self, page_options)

      apply_margin_options(options)
      generate_margin_box

      # Reset the bounding box if the new page has different size or layout
      if last_page && (last_page.size != state.page.size ||
                       last_page.layout != state.page.layout)
        @bounding_box = @margin_box
      end

      use_graphic_settings

      unless options[:orphan]
        state.insert_page(state.page, @page_number)
        @page_number += 1

        if @background
          canvas do
            image(@background, scale: @background_scale, at: bounds.top_left)
          end
        end
        @y = @bounding_box.absolute_top

        float do
          state.on_page_create_action(self)
        end
      end
    end

    # Remove page of the document by index
    #
    #   pdf = Prawn::Document.new
    #   pdf.page_count #=> 1
    #   3.times { pdf.start_new_page }
    #   pdf.page_count #=> 4
    #   pdf.delete_page(-1)
    #   pdf.page_count #=> 3
    #
    def delete_page(index)
      return false if index.abs > (state.pages.count - 1)

      state.pages.delete_at(index)

      state.store.pages.data[:Kids].delete_at(index)
      state.store.pages.data[:Count] -= 1
      @page_number -= 1
      true
    end

    # Returns the number of pages in the document
    #
    #   pdf = Prawn::Document.new
    #   pdf.page_count #=> 1
    #   3.times { pdf.start_new_page }
    #   pdf.page_count #=> 4
    #
    def page_count
      state.page_count
    end

    # Re-opens the page with the given (1-based) page number so that you can
    # draw on it.
    #
    # See Prawn::Document#number_pages for a sample usage of this capability.
    #
    def go_to_page(page_number)
      @page_number = page_number
      state.page = state.pages[page_number - 1]
      generate_margin_box
      @y = @bounding_box.absolute_top
    end

    def y=(new_y)
      @y = new_y
      bounds.update_height
    end

    # The current y drawing position relative to the innermost bounding box,
    # or to the page margins at the top level.
    #
    def cursor
      y - bounds.absolute_bottom
    end

    # Moves to the specified y position in relative terms to the bottom margin.
    #
    def move_cursor_to(new_y)
      self.y = new_y + bounds.absolute_bottom
    end

    # Executes a block and then restores the original y position. If new pages
    # were created during this block, it will teleport back to the original
    # page when done.
    #
    #   pdf.text "A"
    #
    #   pdf.float do
    #     pdf.move_down 100
    #     pdf.text "C"
    #   end
    #
    #   pdf.text "B"
    #
    def float
      original_page = page_number
      original_y = y
      yield
      go_to_page(original_page) unless page_number == original_page
      self.y = original_y
    end

    # Renders the PDF document to string.
    # Pass an open file descriptor to render to file.
    #
    def render(*arguments, &block)
      (1..page_count).each do |i|
        go_to_page i
        repeaters.each { |r| r.run(i) }
      end

      renderer.render(*arguments, &block)
    end

    # Renders the PDF document to file.
    #
    #   pdf.render_file "foo.pdf"
    #
    def render_file(filename)
      File.open(filename, 'wb') { |f| render(f) }
    end

    # The bounds method returns the current bounding box you are currently in,
    # which is by default the box represented by the margin box on the
    # document itself.  When called from within a created <tt>bounding_box</tt>
    # block, the box defined by that call will be returned instead of the
    # document margin box.
    #
    # Another important point about bounding boxes is that all x and
    # y measurements within a bounding box code block are relative to the bottom
    # left corner of the bounding box.
    #
    # For example:
    #
    #  Prawn::Document.new do
    #    # In the default "margin box" of a Prawn document of 0.5in along each
    #    # edge
    #
    #    # Draw a border around the page (the manual way)
    #    stroke do
    #      line(bounds.bottom_left, bounds.bottom_right)
    #      line(bounds.bottom_right, bounds.top_right)
    #      line(bounds.top_right, bounds.top_left)
    #      line(bounds.top_left, bounds.bottom_left)
    #    end
    #
    #    # Draw a border around the page (the easy way)
    #    stroke_bounds
    #  end
    #
    def bounds
      @bounding_box
    end

    # Returns the innermost non-stretchy bounding box.
    #
    # @private
    def reference_bounds
      @bounding_box.reference_bounds
    end

    # Sets Document#bounds to the BoundingBox provided.  See above for a brief
    # description of what a bounding box is.  This function is useful if you
    # really need to change the bounding box manually, but usually, just
    # entering and exiting bounding box code blocks is good enough.
    #
    def bounds=(bounding_box)
      @bounding_box = bounding_box
    end

    # Moves up the document by n points relative to the current position inside
    # the current bounding box.
    #
    def move_up(amount)
      self.y += amount
    end

    # Moves down the document by n points relative to the current position
    # inside the current bounding box.
    #
    def move_down(amount)
      self.y -= amount
    end

    # Moves down the document and then executes a block.
    #
    #   pdf.text "some text"
    #   pdf.pad_top(100) do
    #     pdf.text "This is 100 points below the previous line of text"
    #   end
    #   pdf.text "This text appears right below the previous line of text"
    #
    def pad_top(y)
      move_down(y)
      yield
    end

    # Executes a block then moves down the document
    #
    #   pdf.text "some text"
    #   pdf.pad_bottom(100) do
    #     pdf.text "This text appears right below the previous line of text"
    #   end
    #   pdf.text "This is 100 points below the previous line of text"
    #
    def pad_bottom(y)
      yield
      move_down(y)
    end

    # Moves down the document by y, executes a block, then moves down the
    # document by y again.
    #
    #   pdf.text "some text"
    #   pdf.pad(100) do
    #     pdf.text "This is 100 points below the previous line of text"
    #   end
    #   pdf.text "This is 100 points below the previous line of text"
    #
    def pad(y)
      move_down(y)
      yield
      move_down(y)
    end

    # Indents the specified number of PDF points for the duration of the block
    #
    #  pdf.text "some text"
    #  pdf.indent(20) do
    #    pdf.text "This is indented 20 points"
    #  end
    #  pdf.text "This starts 20 points left of the above line " +
    #           "and is flush with the first line"
    #  pdf.indent 20, 20 do
    #    pdf.text "This line is indented on both sides."
    #  end
    #
    def indent(left, right = 0, &block)
      bounds.indent(left, right, &block)
    end

    # Places a text box on specified pages for page numbering.  This should be
    # called towards the end of document creation, after all your content is
    # already in place.  In your template string, <page> refers to the current
    # page, and <total> refers to the total amount of pages in the document.
    # Page numbering should occur at the end of your Prawn::Document.generate
    # block because the method iterates through existing pages after they are
    # created.
    #
    # Parameters are:
    #
    # <tt>string</tt>:: Template string for page number wording.
    #                   Should include '<page>' and, optionally, '<total>'.
    # <tt>options</tt>:: A hash for page numbering and text box options.
    #     <tt>:page_filter</tt>:: A filter to specify which pages to place page
    #                             numbers on. Refer to the method 'page_match?'
    #     <tt>:start_count_at</tt>:: The starting count to increment pages from.
    #     <tt>:total_pages</tt>:: If provided, will replace <total> with the
    #                             value given. Useful to override the total
    #                             number of pages when using the start_count_at
    #                             option.
    #     <tt>:color</tt>:: Text fill color.
    #
    #     Please refer to Prawn::Text::text_box for additional options
    #     concerning text formatting and placement.
    #
    # Example:
    #   Print page numbers on every page except for the first. Start counting
    #   from five.
    #
    #     Prawn::Document.generate("page_with_numbering.pdf") do
    #       number_pages "<page> in a total of <total>", {
    #         start_count_at: 5,
    #         page_filter: lambda { |pg| pg != 1 },
    #         at: [bounds.right - 50, 0],
    #         align: :right,
    #         size: 14
    #       }
    #     end
    #
    def number_pages(string, options = {})
      opts = options.dup
      start_count_at = opts.delete(:start_count_at).to_i

      page_filter = if opts.key?(:page_filter)
                      opts.delete(:page_filter)
                    else
                      :all
                    end

      total_pages = opts.delete(:total_pages)
      txtcolor = opts.delete(:color)
      # An explicit height so that we can draw page numbers in the margins
      opts[:height] = 50 unless opts.key?(:height)

      start_count = false
      pseudopage = 0
      (1..page_count).each do |p|
        unless start_count
          pseudopage = case start_count_at
                       when 0
                         1
                       else
                         start_count_at.to_i
                       end
        end
        if page_match?(page_filter, p)
          go_to_page(p)
          # have to use fill_color here otherwise text reverts back to default
          # fill color
          fill_color txtcolor unless txtcolor.nil?
          total_pages = total_pages.nil? ? page_count : total_pages
          str = string.gsub('<page>', pseudopage.to_s)
            .gsub('<total>', total_pages.to_s)
          text_box str, opts
          start_count = true # increment page count as soon as first match found
        end
        pseudopage += 1 if start_count
      end
    end

    # @group Experimental API

    # Attempts to group the given block vertically within the current context.
    # First attempts to render it in the current position on the current page.
    # If that attempt overflows, it is tried anew after starting a new context
    # (page or column). Returns a logically true value if the content fits in
    # one page/column, false if a new page or column was needed.
    #
    # Raises CannotGroup if the provided content is too large to fit alone in
    # the current page or column.
    #
    # @private
    def group(*_arguments)
      raise NotImplementedError,
        'Document#group has been disabled because its implementation ' \
        'lead to corrupted documents whenever a page boundary was ' \
        'crossed. We will try to work on reimplementing it in a ' \
        'future release'
    end

    # @private
    def transaction
      raise NotImplementedError,
        'Document#transaction has been disabled because its implementation ' \
        'lead to corrupted documents whenever a page boundary was ' \
        'crossed. We will try to work on reimplementing it in a ' \
        'future release'
    end

    # Provides a way to execute a block of code repeatedly based on a
    # page_filter.
    #
    # Available page filters are:
    #   :all         repeats on every page
    #   :odd         repeats on odd pages
    #   :even        repeats on even pages
    #   some_array   repeats on every page listed in the array
    #   some_range   repeats on every page included in the range
    #   some_lambda  yields page number and repeats for true return values
    def page_match?(page_filter, page_number)
      case page_filter
      when :all
        true
      when :odd
        page_number.odd?
      when :even
        page_number.even?
      when Range, Array
        page_filter.include?(page_number)
      when Proc
        page_filter.call(page_number)
      end
    end

    # @private

    def mask(*fields)
      # Stores the current state of the named attributes, executes the block,
      # and then restores the original values after the block has executed.
      # -- I will remove the nodoc if/when this feature is a little less hacky
      stored = {}
      fields.each { |f| stored[f] = send(f) }
      yield
      fields.each { |f| send("#{f}=", stored[f]) }
    end

    # @group Extension API

    def initialize_first_page(options)
      if options[:skip_page_creation]
        start_new_page(options.merge(orphan: true))
      else
        start_new_page(options)
      end
    end

    ## Internals. Don't depend on them!

    # @private
    attr_accessor :state

    # @private
    def page
      state.page
    end

    private

    # setting override_settings to true ensures that a new graphic state does
    # not end up using previous settings.
    def use_graphic_settings(override_settings = false)
      set_fill_color if current_fill_color != '000000' || override_settings
      set_stroke_color if current_stroke_color != '000000' || override_settings
      write_line_width if line_width != 1 || override_settings
      write_stroke_cap_style if cap_style != :butt || override_settings
      write_stroke_join_style if join_style != :miter || override_settings
      write_stroke_dash if dashed? || override_settings
    end

    def generate_margin_box
      old_margin_box = @margin_box
      page = state.page

      @margin_box = BoundingBox.new(
        self,
        nil, # margin box has no parent
        [page.margins[:left], page.dimensions[-1] - page.margins[:top]],
        width: page.dimensions[-2] -
          (page.margins[:left] + page.margins[:right]),
        height: page.dimensions[-1] -
          (page.margins[:top] + page.margins[:bottom])
      )

      # This check maintains indentation settings across page breaks
      if old_margin_box
        @margin_box.add_left_padding(old_margin_box.total_left_padding)
        @margin_box.add_right_padding(old_margin_box.total_right_padding)
      end

      # we must update bounding box if not flowing from the previous page
      #
      @bounding_box = @margin_box unless @bounding_box&.parent
    end

    def apply_margin_options(options)
      sides = %i[top right bottom left]
      margin = Array(options[:margin])

      # Treat :margin as CSS shorthand with 1-4 values.
      positions = {
        4 => [0, 1, 2, 3], 3 => [0, 1, 2, 1],
        2 => [0, 1, 0, 1], 1 => [0, 0, 0, 0],
        0 => []
      }[margin.length]

      sides.zip(positions).each do |side, pos|
        new_margin = options[:"#{side}_margin"] || (margin[pos] if pos)
        state.page.margins[side] = new_margin if new_margin
      end
    end

    def font_metric_cache #:nodoc:
      @font_metric_cache ||= FontMetricCache.new(self)
    end
  end
end

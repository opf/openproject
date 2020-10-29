# frozen_string_literal: true

# prawn/core/page.rb : Implements low-level representation of a PDF page
#
# Copyright February 2010, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#

require_relative 'graphics_state'

module PDF
  module Core
    class Page #:nodoc:
      attr_accessor :art_indents, :bleeds, :crops, :document, :margins, :stack,
        :trims
      attr_writer :content, :dictionary

      ZERO_INDENTS = {
        left: 0,
        bottom: 0,
        right: 0,
        top: 0
      }.freeze

      def initialize(document, options = {})
        @document = document
        @margins  = options[:margins] || { left: 36,
                                           right: 36,
                                           top: 36,
                                           bottom: 36 }
        @crops = options[:crops] || ZERO_INDENTS
        @bleeds = options[:bleeds] || ZERO_INDENTS
        @trims = options[:trims] || ZERO_INDENTS
        @art_indents = options[:art_indents] || ZERO_INDENTS
        @stack = GraphicStateStack.new(options[:graphic_state])
        @size     = options[:size] || 'LETTER'
        @layout   = options[:layout] || :portrait

        @stamp_stream      = nil
        @stamp_dictionary  = nil

        @content = document.ref({})
        content << 'q' << "\n"
        @dictionary = document.ref(
          Type: :Page,
          Parent: document.state.store.pages,
          MediaBox: dimensions,
          CropBox: crop_box,
          BleedBox: bleed_box,
          TrimBox: trim_box,
          ArtBox: art_box,
          Contents: content
        )

        resources[:ProcSet] = %i[PDF Text ImageB ImageC ImageI]
      end

      def graphic_state
        stack.current_state
      end

      def layout
        return @layout if defined?(@layout) && @layout

        mb = dictionary.data[:MediaBox]
        if mb[3] > mb[2]
          :portrait
        else
          :landscape
        end
      end

      def size
        defined?(@size) && @size || dimensions[2, 2]
      end

      def in_stamp_stream?
        !@stamp_stream.nil?
      end

      def stamp_stream(dictionary)
        @stamp_dictionary = dictionary
        @stamp_stream     = @stamp_dictionary.stream
        graphic_stack_size = stack.stack.size

        document.save_graphics_state
        document.send(:freeze_stamp_graphics)
        yield if block_given?

        until graphic_stack_size == stack.stack.size
          document.restore_graphics_state
        end

        @stamp_stream      = nil
        @stamp_dictionary  = nil
      end

      def content
        @stamp_stream || document.state.store[@content]
      end

      def dictionary
        defined?(@stamp_dictionary) && @stamp_dictionary ||
          document.state.store[@dictionary]
      end

      def resources
        if dictionary.data[:Resources]
          document.deref(dictionary.data[:Resources])
        else
          dictionary.data[:Resources] = {}
        end
      end

      def fonts
        if resources[:Font]
          document.deref(resources[:Font])
        else
          resources[:Font] = {}
        end
      end

      def xobjects
        if resources[:XObject]
          document.deref(resources[:XObject])
        else
          resources[:XObject] = {}
        end
      end

      def ext_gstates
        if resources[:ExtGState]
          document.deref(resources[:ExtGState])
        else
          resources[:ExtGState] = {}
        end
      end

      def finalize
        if dictionary.data[:Contents].is_a?(Array)
          dictionary.data[:Contents].each do |stream|
            stream.stream.compress! if document.compression_enabled?
          end
        elsif document.compression_enabled?
          content.stream.compress!
        end
      end

      def dimensions
        coords = PDF::Core::PageGeometry::SIZES[size] || size
        [0, 0] +
          case layout
          when :portrait
            coords
          when :landscape
            coords.reverse
          else
            raise PDF::Core::Errors::InvalidPageLayout,
              'Layout must be either :portrait or :landscape'
          end
      end

      def art_box
        left, bottom, right, top = dimensions
        [
          left + art_indents[:left],
          bottom + art_indents[:bottom],
          right - art_indents[:right],
          top - art_indents[:top]
        ]
      end

      def bleed_box
        left, bottom, right, top = dimensions
        [
          left + bleeds[:left],
          bottom + bleeds[:bottom],
          right - bleeds[:right],
          top - bleeds[:top]
        ]
      end

      def crop_box
        left, bottom, right, top = dimensions
        [
          left + crops[:left],
          bottom + crops[:bottom],
          right - crops[:right],
          top - crops[:top]
        ]
      end

      def trim_box
        left, bottom, right, top = dimensions
        [
          left + trims[:left],
          bottom + trims[:bottom],
          right - trims[:right],
          top - trims[:top]
        ]
      end

      private

      # some entries in the Page dict can be inherited from parent Pages dicts.
      #
      # Starting with the current page dict, this method will walk up the
      # inheritance chain return the first value that is found for key
      #
      #     inherited_dictionary_value(:MediaBox)
      #     => [ 0, 0, 595, 842 ]
      #
      def inherited_dictionary_value(key, local_dict = nil)
        local_dict ||= dictionary.data

        if local_dict.key?(key)
          local_dict[key]
        elsif local_dict.key?(:Parent)
          inherited_dictionary_value(key, local_dict[:Parent].data)
        end
      end
    end
  end
end

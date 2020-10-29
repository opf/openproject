module PDF
  class Inspector
    class Text < Inspector
      attr_accessor :font_settings, :size, :strings
      attr_accessor :character_spacing, :word_spacing
      attr_accessor :kerned, :text_rendering_mode, :positions
      attr_accessor :horizontal_text_scaling

      def initialize
        @font_settings = []
        @fonts = {}
        @font_objects = {}
        @strings = []
        @character_spacing = []
        @word_spacing = []
        @kerned = []
        @text_rendering_mode = []
        @positions = []
        @horizontal_text_scaling = []
      end

      def page=(page)
        @state = PDF::Reader::PageState.new(page)
        page.fonts.each do |label, stream|
          @fonts[label]        = stream[:BaseFont]
          @font_objects[label] = PDF::Reader::Font.new(page.objects, stream)
        end
      end

      def set_text_font_and_size(*params)
        @state.set_text_font_and_size(*params)
        @font_settings << { name: @fonts[params[0]], size: params[1] }
      end

      def move_text_position(tx, ty)
        @positions << [tx, ty]
      end

      def show_text(*params)
        @kerned << false
        @strings << @state.current_font.to_utf8(params[0])
      end

      def show_text_with_positioning(*params)
        @kerned << true
        # ignore kerning information
        show_text params[0].reject { |e|
          e.is_a? Numeric
        }.join
      end

      def set_text_rendering_mode(*params)
        @state.set_text_rendering_mode(*params)
        @text_rendering_mode << params[0]
      end

      def set_character_spacing(spacing)
        @state.set_character_spacing(spacing)
        @character_spacing << spacing
      end

      def set_word_spacing(*params)
        @state.set_word_spacing(*params)
        @word_spacing << params[0]
      end

      def set_horizontal_text_scaling(scaling)
        @state.set_horizontal_text_scaling(scaling)
        @horizontal_text_scaling << scaling
      end
    end
  end
end

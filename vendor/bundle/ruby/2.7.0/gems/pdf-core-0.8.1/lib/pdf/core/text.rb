# frozen_string_literal: true

# prawn/core/text.rb : Implements low level text helpers for Prawn
#
# Copyright January 2010, Daniel Nelson.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module PDF
  module Core
    module Text #:nodoc:
      # These should be used as a base. Extensions may build on this list
      #
      VALID_OPTIONS = %i[kerning size style].freeze
      MODES = {
        fill: 0,
        stroke: 1,
        fill_stroke: 2,
        invisible: 3,
        fill_clip: 4, stroke_clip: 5,
        fill_stroke_clip: 6,
        clip: 7
      }.freeze

      attr_reader :skip_encoding

      # Low level call to set the current font style and extract text options
      # from an options hash. Should be called from within a save_font block
      #
      def process_text_options(options)
        if options[:style]
          raise 'Bad font family' unless font.family
          font(font.family, style: options[:style])
        end

        # must compare against false to keep kerning on as default
        unless options[:kerning] == false
          options[:kerning] = font.has_kerning_data?
        end

        options[:size] ||= font_size
      end

      # Retrieve the current default kerning setting.
      #
      # Defaults to true
      #
      def default_kerning?
        return true unless defined?(@default_kerning)
        @default_kerning
      end

      # Call with a boolean to set the document-wide kerning setting. This can
      # be overridden using the :kerning text option when drawing text or a text
      # box.
      #
      #   pdf.default_kerning = false
      #   pdf.text('hello world')                   # text is not kerned
      #   pdf.text('hello world', :kerning => true) # text is kerned
      #
      def default_kerning(boolean)
        @default_kerning = boolean
      end

      alias default_kerning= default_kerning

      # Call with no argument to retrieve the current default leading.
      #
      # Call with a number to set the document-wide text leading. This can be
      # overridden using the :leading text option when drawing text or a text
      # box.
      #
      #   pdf.default_leading = 7
      #   pdf.text('hello world')                # a leading of 7 is used
      #   pdf.text('hello world', :leading => 0) # a leading of 0 is used
      #
      # Defaults to 0
      #
      def default_leading(number = nil)
        if number.nil?
          defined?(@default_leading) && @default_leading || 0
        else
          @default_leading = number
        end
      end

      alias default_leading= default_leading

      # Call with no argument to retrieve the current text direction.
      #
      # Call with a symbol to set the document-wide text direction. This can be
      # overridden using the :direction text option when drawing text or a text
      # box.
      #
      #   pdf.text_direction = :rtl
      #   pdf.text('hello world')                     # prints 'dlrow olleh'
      #   pdf.text('hello world', :direction => :ltr) # prints 'hello world'
      #
      # Valid directions are:
      #
      # * :ltr             - left-to-right (default)
      # * :rtl             - right-to-left
      #
      # Side effects:
      #
      # * When printing left-to-right, the default text alignment is :left
      # * When printing right-to-left, the default text alignment is :right
      #
      def text_direction(direction = nil)
        if direction.nil?
          defined?(@text_direction) && @text_direction || :ltr
        else
          @text_direction = direction
        end
      end

      alias text_direction= text_direction

      # Call with no argument to retrieve the current fallback fonts.
      #
      # Call with an array of font names. Each name must be the name of an AFM
      # font or the name that was used to register a family of TTF fonts (see
      # Prawn::Document#font_families). If present, then each glyph will be
      # rendered using the first font that includes the glyph, starting with the
      # current font and then moving through :fallback_fonts from left to right.
      #
      # Call with an empty array to turn off fallback fonts
      #
      # file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
      # font_families['Kai'] = {
      #   :normal => { :file => file, :font => 'Kai' }
      # }
      # file = "#{Prawn::DATADIR}/fonts/Action Man.dfont"
      # font_families['Action Man'] = {
      #   :normal      => { :file => file, :font => 'ActionMan' },
      # }
      # fallback_fonts ['Times-Roman', 'Kai']
      # font 'Action Man'
      # text 'hello ƒ 你好'
      # > hello prints in Action Man
      # > ƒ prints in Times-Roman
      # > 你好 prints in Kai
      #
      # fallback_fonts [] # clears document-wide fallback fonts
      #
      # Side effects:
      #
      # * Increased overhead when fallback fonts are declared as each glyph is
      #   checked to see whether it exists in the current font
      #
      def fallback_fonts(fallback_fonts = nil)
        if fallback_fonts.nil?
          defined?(@fallback_fonts) && @fallback_fonts || []
        else
          @fallback_fonts = fallback_fonts
        end
      end

      alias fallback_fonts= fallback_fonts

      # Call with no argument to retrieve the current text rendering mode.
      #
      # Call with a symbol and block to temporarily change the current
      # text rendering mode.
      #
      #   pdf.text_rendering_mode(:stroke) do
      #     pdf.text('Outlined Text')
      #   end
      #
      # Valid modes are:
      #
      # * :fill             - fill text (default)
      # * :stroke           - stroke text
      # * :fill_stroke      - fill, then stroke text
      # * :invisible        - invisible text
      # * :fill_clip        - fill text then add to path for clipping
      # * :stroke_clip      - stroke text then add to path for clipping
      # * :fill_stroke_clip - fill then stroke text, then add to path for
      #                       clipping
      # * :clip             - add text to path for clipping
      def text_rendering_mode(mode = nil)
        if mode.nil?
          return defined?(@text_rendering_mode) && @text_rendering_mode || :fill
        end
        unless MODES.key?(mode)
          raise ArgumentError,
            "mode must be between one of #{MODES.keys.join(', ')} (#{mode})"
        end
        original_mode = text_rendering_mode

        if original_mode == mode
          yield
        else
          @text_rendering_mode = mode
          add_content "\n#{MODES[mode]} Tr"
          yield
          add_content "\n#{MODES[original_mode]} Tr"
          @text_rendering_mode = original_mode
        end
      end

      def forget_text_rendering_mode!
        @text_rendering_mode = :unknown
      end

      # Increases or decreases the space between characters.
      # For horizontal text, a positive value will increase the space.
      # For veritical text, a positive value will decrease the space.
      #
      def character_spacing(amount = nil)
        if amount.nil?
          return defined?(@character_spacing) && @character_spacing || 0
        end
        original_character_spacing = character_spacing
        if original_character_spacing == amount
          yield
        else
          @character_spacing = amount
          add_content "\n#{PDF::Core.real(amount)} Tc"
          yield
          add_content "\n#{PDF::Core.real(original_character_spacing)} Tc"
          @character_spacing = original_character_spacing
        end
      end

      # Increases or decreases the space between words.
      # For horizontal text, a positive value will increase the space.
      # For veritical text, a positive value will decrease the space.
      #
      def word_spacing(amount = nil)
        return defined?(@word_spacing) && @word_spacing || 0 if amount.nil?
        original_word_spacing = word_spacing
        if original_word_spacing == amount
          yield
        else
          @word_spacing = amount
          add_content "\n#{PDF::Core.real(amount)} Tw"
          yield
          add_content "\n#{PDF::Core.real(original_word_spacing)} Tw"

          @word_spacing = original_word_spacing
        end
      end

      # Set the horizontal scaling. amount is a number specifying the
      # percentage of the normal width.
      def horizontal_text_scaling(amount = nil)
        if amount.nil?
          return defined?(@horizontal_text_scaling) &&
                 @horizontal_text_scaling || 100
        end

        original_horizontal_text_scaling = horizontal_text_scaling
        if original_horizontal_text_scaling == amount
          yield
        else
          @horizontal_text_scaling = amount
          add_content "\n#{PDF::Core.real(amount)} Tz"
          yield
          add_content "\n#{PDF::Core.real(original_horizontal_text_scaling)} Tz"
          @horizontal_text_scaling = original_horizontal_text_scaling
        end
      end

      # rubocop: disable Naming/UncommunicativeMethodParamName
      def add_text_content(text, x, y, options)
        chunks = font.encode_text(text, options)

        add_content "\nBT"

        if options[:rotate]
          rad = options[:rotate].to_f * Math::PI / 180
          array = [
            Math.cos(rad),
            Math.sin(rad),
            -Math.sin(rad),
            Math.cos(rad),
            x, y
          ]
          add_content "#{PDF::Core.real_params(array)} Tm"
        else
          add_content "#{PDF::Core.real_params([x, y])} Td"
        end

        chunks.each do |(subset, string)|
          font.add_to_current_page(subset)
          add_content [
            PDF::Core.pdf_object(font.identifier_for(subset), true),
            PDF::Core.pdf_object(font_size, true),
            'Tf'
          ].join(' ')

          operation = options[:kerning] && string.is_a?(Array) ? 'TJ' : 'Tj'
          add_content PDF::Core.pdf_object(string, true) + ' ' + operation
        end

        add_content "ET\n"
      end
      # rubocop: enable Naming/UncommunicativeMethodParamName
    end
  end
end

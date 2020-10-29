# frozen_string_literal: true

# text.rb : Implements PDF text primitives
#
# Copyright May 2008, Gregory Brown. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'zlib'

require_relative 'text/formatted'
require_relative 'text/box'

module Prawn
  module Text
    include PDF::Core::Text
    include Prawn::Text::Formatted

    # No-Break Space
    NBSP = "\u00A0"
    # Zero Width Space (indicate word boundaries without a space)
    ZWSP = "\u200B"
    # Soft Hyphen (invisible, except when causing a line break)
    SHY = "\u00AD"

    # @group Stable API

    # If you want text to flow onto a new page or between columns, this is the
    # method to use. If, instead, if you want to place bounded text outside of
    # the flow of a document (for captions, labels, charts, etc.), use Text::Box
    # or its convenience method text_box.
    #
    # Draws text on the page. Prawn attempts to wrap the text to fit within your
    # current bounding box (or margin_box if no bounding box is being used).
    # Text will flow onto the next page when it reaches the bottom of the
    # bounding box. Text wrap in Prawn does not re-flow linebreaks, so if you
    # want fully automated text wrapping, be sure to remove newlines before
    # attempting to draw your string.
    #
    # == Examples
    #
    #   pdf.text "Will be wrapped when it hits the edge of your bounding box"
    #   pdf.text "This will be centered", :align => :center
    #   pdf.text "This will be right aligned", :align => :right
    #   pdf.text "This <i>includes <b>inline</b></i> <font size='24'>" +
    #            "formatting</font>", :inline_format => true
    #
    # If your font contains kerning pair data that Prawn can parse, the
    # text will be kerned by default. You can disable kerning by including
    # a false <tt>:kerning</tt> option. If you want to disable kerning on an
    # entire document, set default_kerning = false for that document
    #
    # === Text Positioning Details
    #
    # The text is positioned at font.ascender below the baseline,
    # making it easy to use this method within bounding boxes and spans.
    #
    # == Encoding
    #
    # Note that strings passed to this function should be encoded as UTF-8.
    # If you get unexpected characters appearing in your rendered document,
    # check this.
    #
    # If the current font is a built-in one, although the string must be
    # encoded as UTF-8, only characters that are available in WinAnsi
    # are allowed.
    #
    # If an empty box is rendered to your PDF instead of the character you
    # wanted it usually means the current font doesn't include that character.
    #
    # == Options (default values marked in [])
    #
    # <tt>:inline_format</tt>::
    #      <tt>boolean</tt>. If true, then the string parameter is interpreted
    #      as a HTML-esque string that recognizes the following tags
    #      (assuming the default text formatter is used):
    #      <tt>\<b></b></tt>:: bold
    #      <tt>\<i></i></tt>:: italic
    #      <tt>\<u></u></tt>:: underline
    #      <tt>\<strikethrough></strikethrough></tt>:: strikethrough
    #      <tt>\<sub></sub></tt>:: subscript
    #      <tt>\<sup></sup></tt>:: superscript
    #      <tt>\<font></font></tt>::
    #          with the following attributes (using double or single quotes)
    #            <tt>size="24"</tt>::
    #                attribute for setting size
    #            <tt>character_spacing="2.5"</tt>::
    #                attribute for setting character spacing
    #            <tt>name="Helvetica"</tt>::
    #                attribute for setting the font. The font name must be an
    #                AFM font with the desired faces or must be a font that is
    #                already registered using Prawn::Document#font_families
    #      <tt>\<color></color></tt>::
    #          with the following attributes
    #            <tt>rgb="ffffff" or rgb="#ffffff"</tt>::
    #            <tt>c="100" m="100" y="100" k="100"</tt>::
    #      <tt>\<link></link></tt>::
    #          with the following attributes
    #            <tt>href="http://example.com"</tt>:: an external link
    #          Note that you must explicitly underline and color using the
    #          appropriate tags if you which to draw attention to the link
    #
    # <tt>:kerning</tt>:: <tt>boolean</tt>. Whether or not to use kerning (if it
    #                     is available with the current font)
    #                     [value of document.default_kerning?]
    # <tt>:size</tt>:: <tt>number</tt>. The font size to use. [current font
    #                  size]
    # <tt>:color</tt>:: an RGB color ("ff0000") or CMYK array [10, 20, 30, 40].
    # <tt>:character_spacing</tt>:: <tt>number</tt>. The amount of space to add
    #                               to or remove from the default character
    #                               spacing. [0]
    # <tt>:style</tt>:: The style to use. The requested style must be part of
    #                   the current font familly. [current style]
    # <tt>:indent_paragraphs</tt>:: <tt>number</tt>. The amount to indent the
    #                               first line of each paragraph. Omit this
    #                               option if you do not want indenting.
    # <tt>:direction</tt>::
    #     <tt>:ltr</tt>, <tt>:rtl</tt>, Direction of the text (left-to-right
    #     or right-to-left) [value of document.text_direction]
    # <tt>:fallback_fonts</tt>::
    #     An array of font names. Each name must be the name of an AFM font or
    #     the name that was used to register a family of TTF fonts (see
    #     Prawn::Document#font_families). If present, then each glyph will be
    #     rendered using the first font that includes the glyph, starting with
    #     the current font and then moving through :fallback_fonts from
    #     left to right.
    # <tt>:align</tt>::
    #     <tt>:left</tt>, <tt>:center</tt>, <tt>:right</tt>, or
    #     <tt>:justify</tt> Alignment within the bounding box
    #     [:left if direction is :ltr, :right if direction is :rtl]
    # <tt>:valign</tt>:: <tt>:top</tt>, <tt>:center</tt>, or <tt>:bottom</tt>.
    #                    Vertical alignment within the bounding box [:top]
    # <tt>:leading</tt>::
    #     <tt>number</tt>. Additional space between lines [value of
    #     document.default_leading]
    # <tt>:final_gap</tt>:: <tt>boolean</tt>. If true, then the space between
    #                       each line is included below the last line;
    #                       otherwise, document.y is placed just below the
    #                       descender of the last line printed [true]
    # <tt>:mode</tt>:: The text rendering mode to use. Use this to specify if
    #                  the text should render with the fill color, stroke color
    #                  or both. See the comments to text_rendering_mode() to see
    #                  a list of valid options. [0]
    #
    # == Exceptions
    #
    # Raises <tt>ArgumentError</tt> if <tt>:at</tt> option included
    #
    # Raises <tt>Prawn::Errrors::CannotFit</tt> if not wide enough to print
    # any text
    #
    def text(string, options = {})
      return false if string.nil?

      # we modify the options. don't change the user's hash
      options = options.dup

      p = options[:inline_format]
      if p
        p = [] unless p.is_a?(Array)
        options.delete(:inline_format)
        array = text_formatter.format(string, *p)
      else
        array = [{ text: string }]
      end

      formatted_text(array, options)
    end

    # Draws formatted text to the page.
    # Formatted text is comprised of an array of hashes, where each hash defines
    # text and format information. See Text::Formatted#formatted_text_box for
    # more information on the structure of this array
    #
    # == Example
    #
    #   text([{ :text => "hello" },
    #         { :text => "world",
    #           :size => 24,
    #           :styles => [:bold, :italic] }])
    #
    # == Options
    #
    # Accepts the same options as #text
    #
    # == Exceptions
    #
    # Same as for #text
    #
    def formatted_text(array, options = {})
      options = inspect_options_for_text(options.dup)

      color = options.delete(:color)
      if color
        array = array.map do |fragment|
          fragment[:color] ? fragment : fragment.merge(color: color)
        end
      end

      if @indent_paragraphs
        text_formatter.array_paragraphs(array).each do |paragraph|
          remaining_text = draw_indented_formatted_line(paragraph, options)

          if @no_text_printed
            # unless this paragraph was an empty line
            unless @all_text_printed
              @bounding_box.move_past_bottom
              remaining_text = draw_indented_formatted_line(paragraph, options)
            end
          end

          unless @all_text_printed
            remaining_text = fill_formatted_text_box(remaining_text, options)
            draw_remaining_formatted_text_on_new_pages(remaining_text, options)
          end
        end
      else
        remaining_text = fill_formatted_text_box(array, options)
        draw_remaining_formatted_text_on_new_pages(remaining_text, options)
      end
    end

    # Draws text on the page, beginning at the point specified by the :at option
    # the string is assumed to be pre-formatted to properly fit the page.
    #
    #   pdf.draw_text "Hello World", :at => [100,100]
    #   pdf.draw_text "Goodbye World", :at => [50,50], :size => 16
    #
    # If your font contains kerning pair data that Prawn can parse, the
    # text will be kerned by default. You can disable kerning by including
    # a false <tt>:kerning</tt> option. If you want to disable kerning on an
    # entire document, set default_kerning = false for that document
    #
    # === Text Positioning Details:
    #
    # Prawn will position your text by the left-most edge of its baseline, and
    # flow along a single line.  (This means that :align will not work)
    #
    # == Rotation
    #
    # Text can be rotated before it is placed on the canvas by specifying the
    # <tt>:rotate</tt> option with a given angle. Rotation occurs
    # counter-clockwise.
    #
    # == Encoding
    #
    # Note that strings passed to this function should be encoded as UTF-8.
    # If you get unexpected characters appearing in your rendered document,
    # check this.
    #
    # If the current font is a built-in one, although the string must be
    # encoded as UTF-8, only characters that are available in WinAnsi
    # are allowed.
    #
    # If an empty box is rendered to your PDF instead of the character you
    # wanted it usually means the current font doesn't include that character.
    #
    # == Options (default values marked in [])
    #
    # <tt>:at</tt>:: <tt>[x, y]</tt>(required). The position at which to start
    #                the text
    # <tt>:kerning</tt>:: <tt>boolean</tt>. Whether or not to use kerning (if it
    #                     is available with the current font)
    #                     [value of default_kerning?]
    # <tt>:size</tt>:: <tt>number</tt>. The font size to use. [current font
    #                  size]
    # <tt>:style</tt>:: The style to use. The requested style must be part of
    #                   the current font familly. [current style]
    #
    # <tt>:rotate</tt>:: <tt>number</tt>. The angle to which to rotate text
    #
    # == Exceptions
    #
    # Raises <tt>ArgumentError</tt> if <tt>:at</tt> option omitted
    #
    # Raises <tt>ArgumentError</tt> if <tt>:align</tt> option included
    #
    def draw_text(text, options)
      options = inspect_options_for_draw_text(options.dup)

      # dup because normalize_encoding changes the string
      text = text.to_s.dup
      save_font do
        process_text_options(options)
        text = font.normalize_encoding(text)
        font_size(options[:size]) { draw_text!(text, options) }
      end
    end

    # Low level text placement method. All font and size alterations
    # should already be set
    #
    def draw_text!(text, options)
      unless font.unicode? || font.class.hide_m17n_warning || text.ascii_only?
        warn "PDF's built-in fonts have very limited support for " \
             "internationalized text.\nIf you need full UTF-8 support, " \
             "consider using an external font instead.\n\nTo disable this " \
             "warning, add the following line to your code:\n" \
             "Prawn::Fonts::AFM.hide_m17n_warning = true\n"

        font.class.hide_m17n_warning = true
      end

      x, y = map_to_absolute(options[:at])
      add_text_content(text, x, y, options)
    end

    # Gets height of text in PDF points.
    # Same options as #text, except as noted.
    # Not compatible with :indent_paragraphs option
    #
    # ==Example
    #
    #   height_of("hello\nworld")
    #
    # == Exceptions
    #
    # Raises <tt>NotImplementedError</tt> if <tt>:indent_paragraphs</tt>
    # option included
    #
    # Raises <tt>Prawn::Errrors::CannotFit</tt> if not wide enough to print
    # any text
    #
    def height_of(string, options = {})
      height_of_formatted([{ text: string }], options)
    end

    # Gets height of formatted text in PDF points.
    # See documentation for #height_of.
    #
    # ==Example
    #
    #   height_of_formatted([{ :text => "hello" },
    #                        { :text => "world",
    #                          :size => 24,
    #                          :styles => [:bold, :italic] }])
    #
    def height_of_formatted(array, options = {})
      if options[:indent_paragraphs]
        raise NotImplementedError, ':indent_paragraphs option not available' \
          'with height_of'
      end
      process_final_gap_option(options)
      box = Text::Formatted::Box.new(
        array,
        options.merge(height: 100_000_000, document: self)
      )
      box.render(dry_run: true)

      height = box.height
      height += box.line_gap + box.leading if @final_gap
      height
    end

    private

    def draw_remaining_formatted_text_on_new_pages(remaining_text, options)
      until remaining_text.empty?
        @bounding_box.move_past_bottom
        previous_remaining_text = remaining_text
        remaining_text = fill_formatted_text_box(remaining_text, options)
        break if remaining_text == previous_remaining_text
      end
    end

    def draw_indented_formatted_line(string, options)
      gap = if options.fetch(:direction, text_direction) == :ltr
              [@indent_paragraphs, 0]
            else
              [0, @indent_paragraphs]
            end

      indent(*gap) do
        fill_formatted_text_box(string, options.dup.merge(single_line: true))
      end
    end

    def fill_formatted_text_box(text, options)
      merge_text_box_positioning_options(options)
      box = Text::Formatted::Box.new(text, options)
      remaining_text = box.render
      @no_text_printed = box.nothing_printed?
      @all_text_printed = box.everything_printed?

      self.y -= box.height
      self.y -= box.line_gap + box.leading if @final_gap

      remaining_text
    end

    def merge_text_box_positioning_options(options)
      bottom =
        if @bounding_box.stretchy?
          @margin_box.absolute_bottom
        else
          @bounding_box.absolute_bottom
        end

      options[:height] = y - bottom
      options[:width] = bounds.width
      options[:at] = [
        @bounding_box.left_side - @bounding_box.absolute_left,
        y - @bounding_box.absolute_bottom
      ]
    end

    def inspect_options_for_draw_text(options)
      if options[:at].nil?
        raise ArgumentError, 'The :at option is required for draw_text'
      elsif options[:align]
        raise ArgumentError, 'The :align option does not work with draw_text'
      end

      if options[:kerning].nil?
        options[:kerning] = default_kerning?
      end
      valid_options = PDF::Core::Text::VALID_OPTIONS + %i[at rotate]
      Prawn.verify_options(valid_options, options)
      options
    end

    def inspect_options_for_text(options)
      if options[:at]
        raise ArgumentError, ':at is no longer a valid option with text.' \
                             'use draw_text or text_box instead'
      end
      process_final_gap_option(options)
      process_indent_paragraphs_option(options)
      options[:document] = self
      options
    end

    def process_final_gap_option(options)
      @final_gap = options[:final_gap].nil? || options[:final_gap]
      options.delete(:final_gap)
    end

    def process_indent_paragraphs_option(options)
      @indent_paragraphs = options[:indent_paragraphs]
      options.delete(:indent_paragraphs)
    end

    def move_text_position(amount)
      bottom =
        if @bounding_box.stretchy?
          @margin_box.absolute_bottom
        else
          @bounding_box.absolute_bottom
        end

      @bounding_box.move_past_bottom if (y - amount) < bottom

      self.y -= amount
    end
  end
end

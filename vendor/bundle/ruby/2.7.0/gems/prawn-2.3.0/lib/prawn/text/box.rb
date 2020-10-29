# frozen_string_literal: true

# text/rectangle.rb : Implements text boxes
#
# Copyright November 2009, Daniel Nelson. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#

require_relative 'formatted/box'

module Prawn
  module Text
    # @group Stable API

    # Draws the requested text into a box. When the text overflows
    # the rectangle, you shrink to fit, or truncate the text. Text
    # boxes are independent of the document y position.
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
    # <tt>:kerning</tt>:: <tt>boolean</tt>. Whether or not to use kerning (if it
    #                     is available with the current font)
    #                     [value of document.default_kerning?]
    # <tt>:size</tt>:: <tt>number</tt>. The font size to use. [current font
    #                  size]
    # <tt>:character_spacing</tt>:: <tt>number</tt>. The amount of space to add
    #                               to or remove from the default character
    #                               spacing. [0]
    # <tt>:disable_wrap_by_char</tt>:: <tt>boolean</tt> Whether
    # or not to prevent mid-word breaks when text does not fit in box. [false]
    # <tt>:mode</tt>:: <tt>symbol</tt>. The text rendering mode. See
    #                  documentation for Prawn::Document#text_rendering_mode
    #                  for a list of valid options. [:fill]
    # <tt>:style</tt>:: The style to use. The requested style must be part of
    #                   the current font familly. [current style]
    #
    # <tt>:at</tt>::
    #     <tt>[x, y]</tt>. The upper left corner of the box
    #     [@document.bounds.left, @document.bounds.top]
    # <tt>:width</tt>::
    #     <tt>number</tt>. The width of the box
    #     [@document.bounds.right - @at[0]]
    # <tt>:height</tt>::
    #     <tt>number</tt>. The height of the box [default_height()]
    # <tt>:direction</tt>::
    #     <tt>:ltr</tt>, <tt>:rtl</tt>, Direction of the text (left-to-right
    #     or right-to-left) [value of document.text_direction]
    # <tt>:fallback_fonts</tt>::
    #     An array of font names. Each name must be the name of an AFM font or
    #     the name that was used to register a family of external fonts (see
    #     Prawn::Document#font_families). If present, then each glyph will be
    #     rendered using the first font that includes the glyph, starting with
    #     the current font and then moving through :fallback_fonts from
    #     left to right.
    # <tt>:align</tt>::
    #     <tt>:left</tt>, <tt>:center</tt>, <tt>:right</tt>, or
    #     <tt>:justify</tt> Alignment within the bounding box
    #     [:left if direction is :ltr, :right if direction is :rtl]
    # <tt>:valign</tt>::
    #     <tt>:top</tt>, <tt>:center</tt>, or <tt>:bottom</tt>. Vertical
    #     alignment within the bounding box [:top]
    # <tt>:rotate</tt>::
    #     <tt>number</tt>. The angle to rotate the text
    # <tt>:rotate_around</tt>::
    #     <tt>:center</tt>, <tt>:upper_left</tt>, <tt>:upper_right</tt>,
    #     <tt>:lower_right</tt>, or <tt>:lower_left</tt>. The point around which
    #     to rotate the text [:upper_left]
    # <tt>:leading</tt>::
    #     <tt>number</tt>. Additional space between lines [value of
    #     document.default_leading]
    # <tt>:single_line</tt>::
    #     <tt>boolean</tt>. If true, then only the first line will be drawn
    #     [false]
    # <tt>:overflow</tt>::
    #     <tt>:truncate</tt>, <tt>:shrink_to_fit</tt>, or <tt>:expand</tt>
    #     This controls the behavior when the amount of text
    #     exceeds the available space. [:truncate]
    # <tt>:min_font_size</tt>::
    #     <tt>number</tt>. The minimum font size to use when :overflow is set to
    #     :shrink_to_fit (that is the font size will not be reduced to less than
    #     this value, even if it means that some text will be cut off). [5]
    #
    # == Returns
    #
    # Returns any text that did not print under the current settings.
    #
    # == Exceptions
    #
    # Raises <tt>Prawn::Errors::CannotFit</tt> if not wide enough to print
    # any text
    #
    def text_box(string, options = {})
      options = options.dup
      options[:document] = self

      box = if options[:inline_format]
              p = options.delete(:inline_format)
              p = [] unless p.is_a?(Array)
              array = text_formatter.format(string, *p)
              Text::Formatted::Box.new(array, options)
            else
              Text::Box.new(string, options)
            end

      box.render
    end

    # @group Experimental API

    # Generally, one would use the Prawn::Text#text_box convenience
    # method. However, using Text::Box.new in conjunction with
    # #render(:dry_run=> true) enables one to do look-ahead calculations prior
    # to placing text on the page, or to determine how much vertical space was
    # consumed by the printed text
    #
    class Box < Prawn::Text::Formatted::Box
      def initialize(string, options = {})
        super([{ text: string }], options)
      end

      def render(flags = {})
        leftover = super(flags)
        leftover.collect { |hash| hash[:text] }.join
      end
    end
  end
end

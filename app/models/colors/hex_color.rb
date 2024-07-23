module Colors
  module HexColor
    ##
    # Get the fill style for this color.
    # If the color is light, use a dark font.
    # Otherwise, use a white font.
    def color_styles(light_color: "#FFFFFF", dark_color: "#333333")
      { color: contrasting_font_color(light: light_color, dark: dark_color), "background-color": hexcode }
    end

    def contrasting_font_color(light: "#FFFFFF", dark: "#333333")
      bright? ? dark : light
    end

    ##
    # Returns whether the color is bright according to
    # YIQ lightness.
    def bright?
      brightness_yiq >= 150
    end

    ##
    # Returns whether the color is very bright according to
    # YIQ lightness.
    def super_bright?
      brightness_yiq >= 200
    end

    ##
    # Sum the color values of each channel
    # Same as in frontend color-contrast.functions.ts
    def brightness_yiq
      r, g, b = rgb_colors
      ((r * 299) + (g * 587) + (b * 114)) / 1000
    end

    ##
    # Splits the hexcode into rbg color array
    def rgb_colors
      hexcode
        .delete("#") # Remove trailing #
        .scan(/../) # Pair hex chars
        .map(&:hex) # to int
    end

    def rgb_modify(&)
      rgb_colors
        .map(&)
        .map(&:round)
        .map { |val| [val, 255].min }
    end

    ##
    # Darken this color by the given decimal amount
    def darken(amount)
      blend 0, 1 - amount
    end

    ##
    # Lighten this color by the given decimal amount
    def lighten(amount)
      blend 255, 1 - amount
    end

    ##
    # Blend the color with the same mix_value for all channels
    # and the given opacity
    def blend(mix_value, opacity)
      r, g, b = rgb_modify { |channel| (channel * opacity) + (mix_value * (1 - opacity)) }
      "#%<r>02x%<g>02x%<b>02x" % { r:, g:, b: }
    end

    # rubocop:disable Metrics/AbcSize
    def normalize_hexcode
      return unless hexcode.present? && hexcode_changed?

      self.hexcode = hexcode.strip.upcase

      unless hexcode.starts_with? "#"
        self.hexcode = "##{hexcode}"
      end

      if hexcode.size == 4 # =~ /#.../
        self.hexcode = hexcode.gsub(/([^#])/, '\1\1')
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end

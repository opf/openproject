# A quick and dirty class for converting color palette values to RGB values.
# The values below have the form 0xRRGGBB, where RR is the red level, GG the 
# green level, and BB the blue level. Each level is a value from 0 to 255,
# just as one would expect in HTML markup.

# Future directions may include:
#  - support for mapping RGB values to "best fit" palette values
#
# by Dan Caugherty https://github.com/dancaugherty/spreadsheet/compare/master...rgb

module Spreadsheet
  module Excel
    class Rgb
      attr_accessor :r, :g, :b

      @@RGB_MAP = {
        :xls_color_0     => 0x000000,
        :xls_color_1     => 0xffffff,
        :xls_color_2     => 0xff0000,
        :xls_color_3     => 0x00ff00,
        :xls_color_4     => 0x0000ff,
        :xls_color_5     => 0xffff00,
        :xls_color_6     => 0xff00ff,
        :xls_color_7     => 0x00ffff,
        :xls_color_8     => 0x800000,
        :xls_color_9     => 0x008000,
        :xls_color_10    => 0x008000,
        :xls_color_11    => 0x000080,
        :xls_color_12    => 0x808080,
        :xls_color_13    => 0x008080,
        :xls_color_14    => 0xc0c0c0,
        :xls_color_15    => 0x808080,
        :xls_color_16    => 0x9999ff,
        :xls_color_17    => 0x993366,
        :xls_color_18    => 0xffffcc,
        :xls_color_19    => 0xccffff,
        :xls_color_20    => 0x660066,
        :xls_color_21    => 0xff8080,
        :xls_color_22    => 0x0066cc,
        :xls_color_23    => 0xccccff,
        :xls_color_24    => 0x000080,
        :xls_color_25    => 0xff00ff,
        :xls_color_26    => 0xffff00,
        :xls_color_27    => 0x00ffff,
        :xls_color_28    => 0x800080,
        :xls_color_29    => 0x800000,
        :xls_color_30    => 0x008080,
        :xls_color_31    => 0x0000ff,
        :xls_color_32    => 0x00ccff,
        :xls_color_33    => 0xccffff,
        :xls_color_34    => 0xccffcc,
        :xls_color_35    => 0xffff99,
        :xls_color_36    => 0x99ccff,
        :xls_color_37    => 0xff99cc,
        :xls_color_38    => 0xcc99ff,
        :xls_color_39    => 0xffcc99,
        :xls_color_40    => 0x3366ff,
        :xls_color_41    => 0x33cccc,
        :xls_color_42    => 0x99cc00,
        :xls_color_43    => 0xffcc00,
        :xls_color_44    => 0xff9900,
        :xls_color_45    => 0xff6600,
        :xls_color_46    => 0x666699,
        :xls_color_47    => 0x969696,
        :xls_color_48    => 0x003366,
        :xls_color_49    => 0x339966,
        :xls_color_50    => 0x003300,
        :xls_color_51    => 0x333300,
        :xls_color_52    => 0x993300,
        :xls_color_53    => 0x993366,
        :xls_color_54    => 0x333399,
        :xls_color_55    => 0x333333,
        :builtin_black   => 0x000000,
        :builtin_white   => 0xffffff,
        :builtin_red     => 0xff0000,
        :builtin_green   => 0x00ff00,
        :builtin_blue    => 0x0000ff,
        :builtin_yellow  => 0xffff00,
        :builtin_magenta => 0xff00ff,
        :builtin_cyan    => 0x00ffff,
        :aqua            => 0x00ffff,
        :black           => 0x000000,
        :blue            => 0x0000ff,
        :cyan            => 0x00ffff,
        :brown           => 0x800000,
        :fuchsia         => 0xff00ff,
        :gray            => 0x808080,
        :grey            => 0x808080,
        :green           => 0x008000,
        :lime            => 0x00ff00,
        :magenta         => 0xff00ff,
        :navy            => 0x000080,
        :orange          => 0xff9900,
        :purple          => 0x800080,
        :red             => 0xff0000,
        :silver          => 0xc0c0c0,
        :white           => 0xffffff,
        :yellow          => 0xffff00
      }

      def self.to_rgb color_symbol
        col = @@RGB_MAP[color_symbol]
        return Rgb.new(col >> 16, (col & 0xff00) >> 8, col & 0xff) if col
        nil
      end

      def initialize(r,g,b)
         @r = r & 0xff
         @g = g & 0xff
         @b = b & 0xff
      end

      def to_i
         (r * (256 * 256)) + (g * 256) + b
      end

      def as_hex
         to_i.to_s(16)
      end
    end
  end
end

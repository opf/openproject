require 'delegate'
require 'spreadsheet/format'
require 'spreadsheet/excel/internals'

module Spreadsheet
  module Excel
    module Writer
##
# This class encapsulates everything that is needed to write an XF record.
class Format < DelegateClass Spreadsheet::Format
  include Spreadsheet::Excel::Internals
  def Format.boolean *args
    args.each do |key|
      define_method key do
        @format.send("#{key}?") ? 1 : 0
      end
    end
  end
  def Format.color key, default
    define_method key do
      color_code(@format.send(key) || default)
    end
  end
  def Format.line_style key, default
    define_method key do
      style_code(@format.send(key) || default)
    end
  end
  boolean :hidden, :locked, :merge_range, :shrink, :text_justlast, :text_wrap,
          :cross_down, :cross_up
	line_style	:left, 			 :none
	line_style	:right,			 :none
	line_style	:top, 			 :none
	line_style	:bottom,		 :none
  color :left_color,       :black
  color :right_color,      :black
  color :top_color,        :black
  color :bottom_color,     :black
  color :diagonal_color,   :black
  color :pattern_fg_color, :pattern_bg
  color :pattern_bg_color, :pattern_bg
  attr_reader :format
  def initialize writer, workbook, format=workbook.default_format, opts={}
    @opts = { :type => :format }.merge opts
    @format = format
    @writer = writer
    @workbook = workbook
    super format
  end
  def color_code color
    SEDOC_ROLOC[color]
  end
  def style_code style
    SELYTS_ENIL_REDROB_FX[style]
  end
  def font_index
    @writer.font_index @workbook, font.key
  end
  def horizontal_align
    XF_H_ALIGN.fetch @format.horizontal_align, 0
  end
  def num_format
    @writer.number_format_index @workbook, @format.number_format
  end
  def text_direction
    XF_TEXT_DIRECTION.fetch @format.text_direction, 0
  end
  def vertical_align
    XF_V_ALIGN.fetch @format.vertical_align, 2
  end
  def write_op writer, op, *args
    data = args.join
    writer.write [op,data.size].pack("v2")
    writer.write data
  end
  def write_xf writer, type=@opts[:type]
    xf_type = xf_type_prot type
    data = [
      font_index,   # Index to FONT record (➜ 6.43)
      num_format,   # Index to FORMAT record (➜ 6.45)
      xf_type,      #  Bit  Mask    Contents
                    #  2-0  0x0007  XF_TYPE_PROT – XF type, cell protection
                    #               Bit  Mask  Contents
                    #                 0  0x01  1 = Cell is locked
                    #                 1  0x02  1 = Formula is hidden
                    #                 2  0x04  0 = Cell XF; 1 = Style XF
                    # 15-4  0xfff0  Index to parent style XF
                    #               (always 0xfff in style XFs)
      xf_align,     #  Bit  Mask    Contents
                    #  2-0  0x07    XF_HOR_ALIGN – Horizontal alignment
                    #               Value  Horizontal alignment
                    #               0x00   General
                    #               0x01   Left
                    #               0x02   Centred
                    #               0x03   Right
                    #               0x04   Filled
                    #               0x05   Justified (BIFF4-BIFF8X)
                    #               0x06   Centred across selection
                    #                      (BIFF4-BIFF8X)
                    #               0x07   Distributed (BIFF8X)
                    #    3  0x08    1 = Text is wrapped at right border
                    #  6-4  0x70    XF_VERT_ALIGN – Vertical alignment
                    #               Value  Vertical alignment
                    #               0x00   Top
                    #               0x01   Centred
                    #               0x02   Bottom
                    #               0x03   Justified (BIFF5-BIFF8X)
                    #               0x04   Distributed (BIFF8X)
      xf_rotation,  # XF_ROTATION:  Text rotation angle
                    #  Value  Text rotation
                    #      0  Not rotated
                    #   1-90  1 to 90 degrees counterclockwise
                    # 91-180  1 to 90 degrees clockwise
                    #    255  Letters are stacked top-to-bottom,
                    #         but not rotated
      xf_indent,    #  Bit  Mask  Contents
                    #  3-0  0x0f  Indent level
                    #    4  0x10  1 = Shrink content to fit into cell
                    #    5  0x40  1 = Merge Range (djberger)
                    #  7-6  0xc0  Text direction (BIFF8X only)
                    #             0 = According to context
                    #             1 = Left-to-right
                    #             2 = Right-to-left
      xf_used_attr, #  Bit  Mask  Contents
                    #  7-2  0xfc  XF_USED_ATTRIB – Used attributes
                    #             Each bit describes the validity of a
                    #             specific group of attributes. In cell XFs
                    #             a cleared bit means the attributes of the
                    #             parent style XF are used (but only if the
                    #             attributes are valid there), a set bit
                    #             means the attributes of this XF are used.
                    #             In style XFs a cleared bit means the
                    #             attribute setting is valid, a set bit
                    #             means the attribute should be ignored.
                    #             Bit  Mask  Contents
                    #               0  0x01  Flag for number format
                    #               1  0x02  Flag for font
                    #               2  0x04  Flag for horizontal and
                    #                        vertical alignment, text wrap,
                    #                        indentation, orientation,
                    #                        rotation, and text direction
                    #               3  0x08  Flag for border lines
                    #               4  0x10  Flag for background area style
                    #               5  0x20  Flag for cell protection (cell
                    #                        locked and formula hidden)
      xf_borders,   # Cell border lines and background area:
                    #   Bit  Mask        Contents
                    #  3- 0  0x0000000f  Left line style (➜ 3.10)
                    #  7- 4  0x000000f0  Right line style (➜ 3.10)
                    # 11- 8  0x00000f00  Top line style (➜ 3.10)
                    # 15-12  0x0000f000  Bottom line style (➜ 3.10)
                    # 22-16  0x007f0000  Colour index (➜ 6.70)
                    #                    for left line colour
                    # 29-23  0x3f800000  Colour index (➜ 6.70)
                    #                    for right line colour
                    #    30  0x40000000  1 = Diagonal line
                    #                    from top left to right bottom
                    #    31  0x80000000  1 = Diagonal line
                    #                    from bottom left to right top
      xf_brdcolors, #   Bit  Mask        Contents
                    #  6- 0  0x0000007f  Colour index (➜ 6.70)
                    #                    for top line colour
                    # 13- 7  0x00003f80  Colour index (➜ 6.70)
                    #                    for bottom line colour
                    # 20-14  0x001fc000  Colour index (➜ 6.70)
                    #                    for diagonal line colour
                    # 24-21  0x01e00000  Diagonal line style (➜ 3.10)
                    # 31-26  0xfc000000  Fill pattern (➜ 3.11)
      xf_pattern    #   Bit  Mask        Contents
                    #   6-0  0x007f      Colour index (➜ 6.70)
                    #                    for pattern colour
                    #  13-7  0x3f80      Colour index (➜ 6.70)
                    #                    for pattern background
    ]
    write_op writer, 0x00e0, data.pack(binfmt(:xf))
  end
  def xf_align
    align = horizontal_align
    align |= text_wrap      << 3
    align |= vertical_align << 4
    align |= text_justlast  << 7
    align
  end
  def xf_borders
    border  = left
    border |= right       <<  4
    border |= top         <<  8
    border |= bottom      << 12
    border |= left_color  << 16
    border |= right_color << 23
    border |= cross_down  << 30
    border |= cross_up    << 31
    border
  end
  def xf_brdcolors
    border  = top_color
    border |= bottom_color   << 7
    border |= diagonal_color << 14
    border |= pattern        << 26
    border
  end
  def xf_indent
    indent  = indent_level & 0x0f
    indent |= shrink         << 4
    indent |= merge_range    << 5
    indent |= text_direction << 6
    indent
  end
  def xf_pattern
    ptrn  = pattern_fg_color
    ptrn |= pattern_bg_color << 7
    ptrn
  end
  def xf_rotation
    rot = @format.rotation
    if @format.rotation_stacked?
      rot = 255
    elsif rot >= -90 or rotation <= 90
      rot = -rot + 90 if rot < 0
    else
      warn "rotation outside -90..90; rotation set to 0"
      rot = 0
    end
    rot
  end
  def xf_type_prot type
    type = type.to_s.downcase == 'style' ? 0xfff4 : 0x0000
    type |= locked
    type |= hidden << 1
    type
  end
  def xf_used_attr
    atr_num = num_format & 1
    atr_fnt = font_index & 1
    atr_fnt = 1 unless @format.font.color == :text
    atr_alc = 0
    if horizontal_align != 0 \
      || vertical_align != 2 \
      || indent_level > 0 \
      || shrink? || merge_range? || text_wrap?
    then
      atr_alc = 1
    end
    atr_bdr = 1 
    atr_pat = 0
    if  @format.pattern_fg_color != :border \
      || @format.pattern_bg_color != :pattern_bg \
      || pattern != 0x00
    then
      atr_pat = 1
    end
    atr_prot = hidden? || locked? ? 1 : 0
    attrs  = atr_num
    attrs |= atr_fnt << 1
    attrs |= atr_alc << 2
    attrs |= atr_bdr << 3
    attrs |= atr_pat << 4
    attrs |= atr_prot << 5
    attrs << 2
  end
end
    end
  end
end

#-- encoding: UTF-8
module Core::RFPDF
  COLOR_PALETTE = {
      :black => [0x00, 0x00, 0x00],
      :white => [0xff, 0xff, 0xff],
  }.freeze

  # Draw a circle at (<tt>mid_x, mid_y</tt>) with <tt>radius</tt>.
  # 
  # Options are:
  # * <tt>:border</tt> - Draw a border, 0 = no, 1 = yes? Default value is <tt>1</tt>.
  # * <tt>:border_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:border_width</tt> - Default value is <tt>0.5</tt>.
  # * <tt>:fill</tt> - Fill the box, 0 = no, 1 = yes? Default value is <tt>1</tt>.
  # * <tt>:fill_color</tt> - Default value is nothing or <tt>COLOR_PALETTE[:white]</tt>.
  # * <tt>:fill_colorspace</tt> - Default value is :rgb or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_circle(x, y, radius, :border_color => ReportHelper::COLOR_PALETTE[:dark_blue], :border_width => 1)
	#
  def draw_circle(mid_x, mid_y, radius, options = {})
    options[:border] ||= 1
    options[:border_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:border_width] ||= 0.5
    options[:fill] ||= 1
    options[:fill_color] ||= Core::RFPDF::COLOR_PALETTE[:white]
    options[:fill_colorspace] ||= :rgb
    SetLineWidth(options[:border_width])
    set_draw_color_a(options[:border_color])
    set_fill_color_a(options[:fill_color], options[:colorspace])
    fd = ""
    fd = "D" if options[:border] == 1
    fd += "F" if options[:fill] == 1
    Circle(mid_x, mid_y, radius, fd)
  end

  # Draw a line from (<tt>x1, y1</tt>) to (<tt>x2, y2</tt>).
  # 
  # Options are:
  # * <tt>:line_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:line_width</tt> - Default value is <tt>0.5</tt>.
  #
  # Example:
  #
	#   draw_line(x1, y1, x1, y1+h, :line_color => ReportHelper::COLOR_PALETTE[:dark_blue], :line_width => 1)
	#
  def draw_line(x1, y1, x2, y2, options = {})
    options[:line_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:line_width] ||= 0.5
    set_draw_color_a(options[:line_color])
    SetLineWidth(options[:line_width])
    Line(x1, y1, x2, y2)
  end

  # Draw a string of <tt>text</tt> at (<tt>x, y</tt>).
  # 
  # Options are:
  # * <tt>:font_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:font_size</tt> - Default value is <tt>10</tt>.
  # * <tt>:font_style</tt> - Default value is nothing or <tt>''</tt>.
  # * <tt>:colorspace</tt> - Default value is :rgb or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_text(x, y, header_left, :font_size => 10)
	#
  def draw_text(x, y, text, options = {})
    options[:font_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:font] ||= default_font
    options[:font_size] ||= 10
    options[:font_style] ||= ''
    set_text_color_a(options[:font_color], options[:colorspace])
    SetFont(options[:font], options[:font_style], options[:font_size])
    SetXY(x, y)
    Write(options[:font_size] + 4, text)
  end

  # Draw a block of <tt>text</tt> at (<tt>x, y</tt>) bounded by <tt>left_margin</tt> and <tt>right_margin_from_right_edge</tt>. Both
  # margins are measured from their corresponding edge.
  # 
  # Options are:
  # * <tt>:font_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:font_size</tt> - Default value is <tt>10</tt>.
  # * <tt>:font_style</tt> - Default value is nothing or <tt>''</tt>.
  # * <tt>:colorspace</tt> - Default value is :rgb or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_text_block(left_margin, 85, "question", left_margin, 280,
  #       :font_color => ReportHelper::COLOR_PALETTE[:dark_blue],
  #       :font_size => 12,
  #       :font_style => 'I')
	#
  def draw_text_block(x, y, text, left_margin, right_margin_from_right_edge, options = {})
    options[:font] ||= default_font
    options[:font_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:font_size] ||= 10
    options[:font_style] ||= ''
    set_text_color_a(options[:font_color], options[:colorspace])
    SetFont(options[:font], options[:font_style], options[:font_size])
    SetXY(x, y)
    SetLeftMargin(left_margin)
    SetRightMargin(right_margin_from_right_edge)
    Write(options[:font_size] + 4, text)
    SetMargins(0,0,0)
  end

  # Draw a box at (<tt>x, y</tt>), <tt>w</tt> wide and <tt>h</tt> high.
  # 
  # Options are:
  # * <tt>:border</tt> - Draw a border, 0 = no, 1 = yes? Default value is <tt>1</tt>.
  # * <tt>:border_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:border_width</tt> - Default value is <tt>0.5</tt>.
  # * <tt>:fill</tt> - Fill the box, 0 = no, 1 = yes? Default value is <tt>1</tt>.
  # * <tt>:fill_color</tt> - Default value is nothing or <tt>COLOR_PALETTE[:white]</tt>.
  # * <tt>:fill_colorspace</tt> - Default value is :rgb or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_box(x, y - 1, 38, 22)
	#
  def draw_box(x, y, w, h, options = {})
    options[:border] ||= 1
    options[:border_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:border_width] ||= 0.5
    options[:fill] ||= 1
    options[:fill_color] ||= Core::RFPDF::COLOR_PALETTE[:white]
    options[:fill_colorspace] ||= :rgb
    SetLineWidth(options[:border_width])
    set_draw_color_a(options[:border_color])
    set_fill_color_a(options[:fill_color], options[:fill_colorspace])
    fd = ""
    fd = "D" if options[:border] == 1
    fd += "F" if options[:fill] == 1
    Rect(x, y, w, h, fd)
  end
  
  # Draw a string of <tt>text</tt> at (<tt>x, y</tt>) in a box <tt>w</tt> wide and <tt>h</tt> high.
  # 
  # Options are:
  # * <tt>:align</tt> - Vertical alignment 'C' = center, 'L' = left, 'R' = right. Default value is <tt>'C'</tt>.
  # * <tt>:border</tt> - Draw a border, 0 = no, 1 = yes? Default value is <tt>0</tt>.
  # * <tt>:border_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:border_width</tt> - Default value is <tt>0.5</tt>.
  # * <tt>:fill</tt> - Fill the box, 0 = no, 1 = yes? Default value is <tt>1</tt>.
  # * <tt>:fill_color</tt> - Default value is nothing or <tt>COLOR_PALETTE[:white]</tt>.
  # * <tt>:font_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:font_size</tt> - Default value is nothing or <tt>8</tt>.
  # * <tt>:font_style</tt> - 'B' = bold, 'I' = italic, 'U' = underline. Default value is nothing <tt>''</tt>.
  # * <tt>:padding</tt> - Default value is nothing or <tt>2</tt>.
  # * <tt>:x_padding</tt> - Default value is nothing.
  # * <tt>:valign</tt> - 'M' = middle, 'T' = top, 'B' = bottom. Default value is nothing or <tt>'M'</tt>.
  # * <tt>:colorspace</tt> - Default value is :rgb or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_text_box(x, y - 1, 38, 22, 
  #                 "your_score_title", 
  #                 :fill => 0,
  #                 :font_color => ReportHelper::COLOR_PALETTE[:blue], 
  #                 :font_line_spacing => 0,
  #                 :font_style => "B",
  #                 :valign => "M")
	#
  def draw_text_box(x, y, w, h, text, options = {})
    options[:align] ||= 'C'
    options[:border] ||= 0
    options[:border_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:border_width] ||= 0.5
    options[:fill] ||= 1
    options[:fill_color] ||= Core::RFPDF::COLOR_PALETTE[:white]
    options[:font] ||= default_font
    options[:font_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:font_size] ||= 8
    options[:font_line_spacing] ||= options[:font_size] * 0.3
    options[:font_style] ||= ''
    options[:padding] ||= 2
    options[:x_padding] ||= 0
    options[:valign] ||= "M"
		if options[:fill] == 1 or options[:border] == 1
      draw_box(x, y, w, h, options)
  	end    
    SetMargins(0,0,0)
    set_text_color_a(options[:font_color], options[:colorspace])
  	font_size = options[:font_size]
    SetFont(options[:font], options[:font_style], font_size)
  	font_size += options[:font_line_spacing]
  	case options[:valign]
  	  when "B", "bottom"
  	    y -= options[:padding]
  	  when "T", "top"
  	    y += options[:padding]
  	end
  	case options[:align]
  	  when "L", "left"
  	    x += options[:x_padding]
  	    w -= options[:x_padding]
  	    w -= options[:x_padding]
  	  when "R", "right"
  	    x += options[:x_padding]
  	    w -= options[:x_padding]
  	    w -= options[:x_padding]
  	end
    SetXY(x, y)
    if GetStringWidth(text) < w or not text["\n"].nil? and (options[:valign] == "T" || options[:valign] == "top")
      text = text + "\n"
    end
    if GetStringWidth(text) > w or not text["\n"].nil? or (options[:valign] == "B" || options[:valign] == "bottom")
      font_size += options[:font_size] * 0.1
      # TODO 2006-07-21 Level=1 - this is assuming a 2 line text
      SetXY(x, y + ((h - (font_size * 2)) / 2)) if (options[:valign] == "M" || options[:valign] == "middle")
      MultiCell(w, font_size, text, 0, options[:align])
    else
      Cell(w, h, text, 0, 0, options[:align])
    end
  end
  
  # Draw a string of <tt>text</tt> at (<tt>x, y</tt>) as a title.
  # 
  # Options are:
  # * <tt>:font_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:font_size</tt> - Default value is <tt>18</tt>.
  # * <tt>:font_style</tt> - Default value is nothing or <tt>''</tt>.
  # * <tt>:colorspace</tt> - Default value is :rgb or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_title(left_margin, 60, 
	#       "title:", 
	#       :font_color => ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def draw_title(x, y, title, options = {})
    options[:font_color] ||= Core::RFPDF::COLOR_PALETTE[:black]
    options[:font] ||= default_font
    options[:font_size] ||= 18
    options[:font_style] ||= ''
    set_text_color_a(options[:font_color], options[:colorspace])
    SetFont(options[:font], options[:font_style], options[:font_size])
  	SetXY(x, y)
  	Write(options[:font_size] + 2, title)
  end

  # Set the draw color. Default value is <tt>COLOR_PALETTE[:black]</tt>.
  #
  # Example:
  #
	#   set_draw_color_a(ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def set_draw_color_a(color = Core::RFPDF::COLOR_PALETTE[:black])
    SetDrawColor(color[0], color[1], color[2])
  end

  # Set the fill color. Default value is <tt>COLOR_PALETTE[:white]</tt>.
  #
  # Example:
  #
	#   set_fill_color_a(ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def set_fill_color_a(color = Core::RFPDF::COLOR_PALETTE[:white], colorspace = :rgb)
    if colorspace == :cmyk
      SetCmykFillColor(color[0], color[1], color[2], color[3])
    else
      SetFillColor(color[0], color[1], color[2])
    end
  end

  # Set the text color. Default value is <tt>COLOR_PALETTE[:white]</tt>.
  #
  # Example:
  #
	#   set_text_color_a(ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def set_text_color_a(color = Core::RFPDF::COLOR_PALETTE[:black], colorspace = :rgb)
    if colorspace == :cmyk
      SetCmykTextColor(color[0], color[1], color[2], color[3])
    else
      SetTextColor(color[0], color[1], color[2])
    end
  end
    
  # Write a string containing html characters. Default value is <tt>COLOR_PALETTE[:white]</tt>.
  #
  # Options are:
  # * <tt>:height</tt> - Line height. Default value is <tt>20</tt>.
  #
  # Example:
  #
	#   write_html_with_options(html, :height => 12)
	#
	#FIXME 2007-08-07 (EJM) Level=0 - This needs to call the TCPDF version.
  def write_html_with_options(html, options = {})
    options[:fill] ||= 0
    options[:height] ||= 20
    options[:new_line_after] ||= false
    write_html(html, options[:new_line_after], options[:fill], options[:height])
    return
  end 
end
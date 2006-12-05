module RFPDF
  COLOR_PALETTE = {
	  :black => [0x00, 0x00, 0x00],
	  :white => [0xff, 0xff, 0xff],
  }.freeze

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
    options[:line_color] ||= COLOR_PALETTE[:black]
    options[:line_width] ||= 0.5
    set_draw_color(options[:line_color])
    SetLineWidth(options[:line_width])
    Line(x1, y1, x2, y2)
  end

  # Draw a string of <tt>text</tt> at (<tt>x, y</tt>).
  # 
  # Options are:
  # * <tt>:font_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:font_size</tt> - Default value is <tt>10</tt>.
  # * <tt>:font_style</tt> - Default value is nothing or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_text(x, y, header_left, :font_size => 10)
	#
  def draw_text(x, y, text, options = {})
    options[:font_color] ||= COLOR_PALETTE[:black]
    options[:font_size] ||= 10
    options[:font_style] ||= ''
    set_text_color(options[:font_color])
    SetFont('Arial', options[:font_style], options[:font_size])
    SetXY(x, y)
    Write(options[:font_size] + 4, text)
  end

  # Draw a block of <tt>text</tt> at (<tt>x, y</tt>) bounded by <tt>left_margin</tt> and <tt>right_margin</tt>. Both
  # margins are measured from their corresponding edge.
  # 
  # Options are:
  # * <tt>:font_color</tt> - Default value is <tt>COLOR_PALETTE[:black]</tt>.
  # * <tt>:font_size</tt> - Default value is <tt>10</tt>.
  # * <tt>:font_style</tt> - Default value is nothing or <tt>''</tt>.
  #
  # Example:
  #
	#   draw_text_block(left_margin, 85, "question", left_margin, 280,
  #       :font_color => ReportHelper::COLOR_PALETTE[:dark_blue],
  #       :font_size => 12,
  #       :font_style => 'I')
	#
  def draw_text_block(x, y, text, left_margin, right_margin, options = {})
    options[:font_color] ||= COLOR_PALETTE[:black]
    options[:font_size] ||= 10
    options[:font_style] ||= ''
    set_text_color(options[:font_color])
    SetFont('Arial', options[:font_style], options[:font_size])
    SetXY(x, y)
    SetLeftMargin(left_margin)
    SetRightMargin(right_margin)
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
  #
  # Example:
  #
	#   draw_box(x, y - 1, 38, 22)
	#
  def draw_box(x, y, w, h, options = {})
    options[:border] ||= 1
    options[:border_color] ||= COLOR_PALETTE[:black]
    options[:border_width] ||= 0.5
    options[:fill] ||= 1
    options[:fill_color] ||= COLOR_PALETTE[:white]
    SetLineWidth(options[:border_width])
    set_draw_color(options[:border_color])
    set_fill_color(options[:fill_color])
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
  # * <tt>:valign</tt> - 'M' = middle, 'T' = top, 'B' = bottom. Default value is nothing or <tt>'M'</tt>.
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
    options[:border_color] ||= COLOR_PALETTE[:black]
    options[:border_width] ||= 0.5
    options[:fill] ||= 1
    options[:fill_color] ||= COLOR_PALETTE[:white]
    options[:font_color] ||= COLOR_PALETTE[:black]
    options[:font_size] ||= 8
    options[:font_line_spacing] ||= options[:font_size] * 0.3
    options[:font_style] ||= ''
    options[:padding] ||= 2
    options[:valign] ||= "M"
		if options[:fill] == 1 or options[:border] == 1
      draw_box(x, y, w, h, options)
  	end    
    SetMargins(0,0,0)
    set_text_color(options[:font_color])
  	font_size = options[:font_size]
    SetFont('Arial', options[:font_style], font_size)
  	font_size += options[:font_line_spacing]
  	case options[:valign]
  	  when "B"
  	    y -= options[:padding]
        text = "\n" + text if text["\n"].nil?
  	  when "T"
  	    y += options[:padding]
  	end
    SetXY(x, y)
  	if GetStringWidth(text) > w or not text["\n"].nil? or options[:valign] == "T"
    	font_size += options[:font_size] * 0.1
    	#TODO 2006-07-21 Level=1 - this is assuming a 2 line text
    	SetXY(x, y + ((h - (font_size * 2)) / 2)) if options[:valign] == "M"
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
  #
  # Example:
  #
	#   draw_title(left_margin, 60, 
	#       "title:", 
	#       :font_color => ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def draw_title(x, y, title, options = {})
    options[:font_color] ||= COLOR_PALETTE[:black]
    options[:font_size] ||= 18
    options[:font_style] ||= ''
    set_text_color(options[:font_color])
    SetFont('Arial', options[:font_style], options[:font_size])
  	SetXY(x, y)
  	Write(options[:font_size] + 2, title)
  end

  # Set the draw color. Default value is <tt>COLOR_PALETTE[:black]</tt>.
  #
  # Example:
  #
	#   set_draw_color(ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def set_draw_color(color = COLOR_PALETTE[:black])
    SetDrawColor(color[0], color[1], color[2])
  end

  # Set the fill color. Default value is <tt>COLOR_PALETTE[:white]</tt>.
  #
  # Example:
  #
	#   set_fill_color(ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def set_fill_color(color = COLOR_PALETTE[:white])
    SetFillColor(color[0], color[1], color[2])
  end

  # Set the text color. Default value is <tt>COLOR_PALETTE[:white]</tt>.
  #
  # Example:
  #
	#   set_text_color(ReportHelper::COLOR_PALETTE[:dark_blue])
	#
  def set_text_color(color = COLOR_PALETTE[:black])
    SetTextColor(color[0], color[1], color[2])
  end
    
  # Write a string containing html characters. Default value is <tt>COLOR_PALETTE[:white]</tt>.
  #
  # Options are:
  # * <tt>:height</tt> - Line height. Default value is <tt>20</tt>.
  #
  # Example:
  #
	#   write_html(html, :height => 12)
	#
  def write_html(html, options = {})
    options[:height] ||= 20
    #HTML parser
    @href = nil
    @style = {}
    html.gsub!("\n",' ')
    re = %r{ ( <!--.*?--> |
               <  (?:
                  [^<>"] +
                  |
                  "  (?: \\.  |  [^\\"]+  ) *  "
                  ) *
               >
             )  }xm

    html.split(re).each do |value|
      if "<" == value[0,1]
        #Tag
        if (value[1, 1] == '/')
          close_tag(value[2..-2], options)
        else
          tag = value[1..-2]
          open_tag(tag, options)
        end
      else
        #Text
        if @href
          put_link(@href,value)
        else
          Write(options[:height], value)
        end
      end
    end
  end

  def open_tag(tag, options = {}) #:nodoc:
    #Opening tag
    tag = tag.to_s.upcase
    set_style(tag, true) if tag == 'B' or tag == 'I' or tag == 'U'
    @href = options['HREF'] if tag == 'A'
    Ln(options[:height]) if tag == 'BR'
  end

  def close_tag(tag, options = {}) #:nodoc:
    #Closing tag
    tag = tag.to_s.upcase
    set_style(tag, false) if tag == 'B' or tag == 'I' or  tag == 'U'
    @href = '' if $tag == 'A'
  end

  def set_style(tag, enable = true) #:nodoc:
    #Modify style and select corresponding font
    style = ""
    @style[tag] = enable
    ['B','I','U'].each do |s|
      style += s if not @style[s].nil? and @style[s]
    end
    SetFont('', style)
  end

  def put_link(url, txt) #:nodoc:
    #Put a hyperlink
    SetTextColor(0,0,255)
    set_style('U',true)
    Write(5, txt, url)
    set_style('U',false)
    SetTextColor(0)
  end 
end

# class FPDF
#   alias_method :set_margins         , :SetMargins
#   alias_method :set_left_margin      , :SetLeftMargin
#   alias_method :set_top_margin       , :SetTopMargin
#   alias_method :set_right_margin     , :SetRightMargin
#   alias_method :set_auto_pagebreak   , :SetAutoPageBreak
#   alias_method :set_display_mode     , :SetDisplayMode
#   alias_method :set_compression     , :SetCompression
#   alias_method :set_title           , :SetTitle
#   alias_method :set_subject         , :SetSubject
#   alias_method :set_author          , :SetAuthor
#   alias_method :set_keywords        , :SetKeywords
#   alias_method :set_creator         , :SetCreator
#   alias_method :set_draw_color       , :SetDrawColor
#   alias_method :set_fill_color       , :SetFillColor
#   alias_method :set_text_color       , :SetTextColor
#   alias_method :set_line_width       , :SetLineWidth
#   alias_method :set_font            , :SetFont
#   alias_method :set_font_size        , :SetFontSize
#   alias_method :set_link            , :SetLink
#   alias_method :set_y               , :SetY
#   alias_method :set_xy              , :SetXY
#   alias_method :get_string_width     , :GetStringWidth
#   alias_method :get_x               , :GetX
#   alias_method :set_x               , :SetX
#   alias_method :get_y               , :GetY
#   alias_method :accept_pagev_break    , :AcceptPageBreak
#   alias_method :add_font            , :AddFont
#   alias_method :add_link            , :AddLink
#   alias_method :add_page            , :AddPage
#   alias_method :alias_nb_pages       , :AliasNbPages
#   alias_method :cell               , :Cell
#   alias_method :close              , :Close
#   alias_method :error              , :Error
#   alias_method :footer             , :Footer
#   alias_method :header             , :Header
#   alias_method :image              , :Image
#   alias_method :line               , :Line
#   alias_method :link               , :Link
#   alias_method :ln                 , :Ln
#   alias_method :multi_cell          , :MultiCell
#   alias_method :open               , :Open
#   alias_method :Open               , :open
#   alias_method :output             , :Output
#   alias_method :page_no             , :PageNo
#   alias_method :rect               , :Rect
#   alias_method :text               , :Text
#   alias_method :write              , :Write
# end

#-- encoding: UTF-8
#============================================================+
# File name   : tcpdf.rb
# Begin       : 2002-08-03
# Last Update : 2007-03-20
# Author      : Nicola Asuni
# Version     : 1.53.0.TC031
# License     : GNU LGPL (http://www.gnu.org/copyleft/lesser.html)
#
# Description : This is a Ruby class for generating PDF files
#               on-the-fly without requiring external
#               extensions.
#
# IMPORTANT:
# This class is an extension and improvement of the Public Domain
# FPDF class by Olivier Plathey (http://www.fpdf.org).
#
# Main changes by Nicola Asuni:
#    Ruby porting;
#    UTF-8 Unicode support;
#    code refactoring;
#    source code clean up;
#    code style and formatting;
#    source code documentation using phpDocumentor (www.phpdoc.org);
#    All ISO page formats were included;
#    image scale factor;
#    includes methods to parse and printsome XHTML code, supporting the following elements: h1, h2, h3, h4, h5, h6, b, u, i, a, img, p, br, strong, em, font, blockquote, li, ul, ol, hr, td, th, tr, table, sup, sub, small;
#    includes a method to print various barcode formats using an improved version of "Generic Barcode Render Class" by Karim Mribti (http://www.mribti.com/barcode/) (require GD library: http://www.boutell.com/gd/);
#    defines standard Header() and Footer() methods.
#
#   Ported to Ruby by Ed Moss 2007-08-06
#
#============================================================+

#
# TCPDF Class.
# @package com.tecnick.tcpdf
#

PDF_PRODUCER = 'TCPDF via RFPDF 1.53.0.TC031 (http://tcpdf.sourceforge.net)'

module TCPDFFontDescriptor
  @@descriptors = { 'freesans' => {} }
  @@font_name = 'freesans'

  def self.font(font_name)
    @@descriptors[font_name.gsub(".rb", "")]
  end

  def self.define(font_name = 'freesans')
    @@descriptors[font_name] ||= {}
    yield @@descriptors[font_name]
  end
end

# This is a Ruby class for generating PDF files on-the-fly without requiring external extensions.<br>
# This class is an extension and improvement of the FPDF class by Olivier Plathey (http://www.fpdf.org).<br>
# This version contains some changes: [porting to Ruby, support for UTF-8 Unicode, code style and formatting, php documentation (www.phpdoc.org), ISO page formats, minor improvements, image scale factor]<br>
# TCPDF project (http://tcpdf.sourceforge.net) is based on the Public Domain FPDF class by Olivier Plathey (http://www.fpdf.org).<br>
# To add your own TTF fonts please read /fonts/README.TXT
# @name TCPDF
# @package com.tecnick.tcpdf
# @@version 1.53.0.TC031
# @author Nicola Asuni
# @link http://tcpdf.sourceforge.net
# @license http://www.gnu.org/copyleft/lesser.html LGPL
#
class TCPDF
  @@fpdf_charwidths = {}
  @@version = "1.53.0.TC031"

  include RFPDF
  include Core::RFPDF
  include RFPDF::Math

  cattr_accessor :k_cell_height_ratio
  @@k_cell_height_ratio = 1.25

  cattr_accessor :k_blank_image
  @@k_blank_image = ""

  cattr_accessor :k_small_ratio
  @@k_small_ratio = 2/3.0

  cattr_accessor :k_path_cache
  @@k_path_cache = Rails.root.join('tmp').to_s

  cattr_accessor :k_path_url_cache
  @@k_path_url_cache = Rails.root.join('tmp').to_s

  cattr_accessor :decoder

  attr_accessor :buffer

  attr_accessor :diffs

  attr_accessor :color_flag

  attr_accessor :default_table_columns

  attr_accessor :default_font

  attr_accessor :draw_color

  attr_accessor :encoding

  attr_accessor :fill_color

  attr_accessor :fonts

  attr_accessor :font_family

  attr_accessor :font_files

  cattr_accessor :font_path

  attr_accessor :font_style

  attr_accessor :font_size_pt

  attr_accessor :header_width

  attr_accessor :header_logo

  attr_accessor :header_logo_width

  attr_accessor :header_title

  attr_accessor :header_string

  attr_accessor :images

  attr_accessor :img_scale

  attr_accessor :in_footer

  attr_accessor :is_unicode

  attr_accessor :lasth

  attr_accessor :links

  attr_accessor :listordered

  attr_accessor :listcount

  attr_accessor :lispacer

  attr_accessor :n

  attr_accessor :offsets

  attr_accessor :orientation_changes

  attr_accessor :page

  attr_accessor :page_links

  attr_accessor :pages

  attr_accessor :pdf_version

  attr_accessor :prevfill_color

  attr_accessor :prevtext_color

  attr_accessor :print_header

  attr_accessor :print_footer

  attr_accessor :state

  attr_accessor :tableborder

  attr_accessor :tdbegin

  attr_accessor :tdwidth

  attr_accessor :tdheight

  attr_accessor :tdalign

  attr_accessor :tdfill

  attr_accessor :tempfontsize

  attr_accessor :text_color

  attr_accessor :underline

  attr_accessor :ws

  #
  # This is the class constructor.
  # It allows to set up the page format, the orientation and
  # the measure unit used in all the methods (except for the font sizes).
  # @since 1.0
  # @param string :orientation page orientation. Possible values are (case insensitive):<ul><li>P or Portrait (default)</li><li>L or Landscape</li></ul>
  # @param string :unit User measure unit. Possible values are:<ul><li>pt: point</li><li>mm: millimeter (default)</li><li>cm: centimeter</li><li>in: inch</li></ul><br />A point equals 1/72 of inch, that is to say about 0.35 mm (an inch being 2.54 cm). This is a very common unit in typography; font sizes are expressed in that unit.
  # @param mixed :format The format used for pages. It can be either one of the following values (case insensitive) or a custom format in the form of a two-element array containing the width and the height (expressed in the unit given by unit).<ul><li>4A0</li><li>2A0</li><li>A0</li><li>A1</li><li>A2</li><li>A3</li><li>A4 (default)</li><li>A5</li><li>A6</li><li>A7</li><li>A8</li><li>A9</li><li>A10</li><li>B0</li><li>B1</li><li>B2</li><li>B3</li><li>B4</li><li>B5</li><li>B6</li><li>B7</li><li>B8</li><li>B9</li><li>B10</li><li>C0</li><li>C1</li><li>C2</li><li>C3</li><li>C4</li><li>C5</li><li>C6</li><li>C7</li><li>C8</li><li>C9</li><li>C10</li><li>RA0</li><li>RA1</li><li>RA2</li><li>RA3</li><li>RA4</li><li>SRA0</li><li>SRA1</li><li>SRA2</li><li>SRA3</li><li>SRA4</li><li>LETTER</li><li>LEGAL</li><li>EXECUTIVE</li><li>FOLIO</li></ul>
  # @param boolean :unicode TRUE means that the input text is unicode (default = true)
  # @param String :encoding charset encoding; default is UTF-8
  #
  def initialize(orientation = 'P',  unit = 'mm', format = 'A4', unicode = true, encoding = "UTF-8")

    # Set internal character encoding to ASCII#
    #FIXME 2007-05-25 (EJM) Level=0 -
    # if (respond_to?("mb_internal_encoding") and mb_internal_encoding())
    #   @internal_encoding = mb_internal_encoding();
    #   mb_internal_encoding("ASCII");
    # }

    #Some checks
    dochecks();

    begin
      @@decoder = HTMLEntities.new
    rescue
      @@decoder = nil
    end

    #Initialization of properties
    @buffer ||= ''
    @diffs ||= []
    @color_flag ||= false
    @default_table_columns ||= 4
    @default_font ||= "FreeSans" if unicode
    @default_font ||= "Helvetica"
    @draw_color ||= '0 G'
    @encoding ||= "UTF-8"
    @fill_color ||= '0 g'
    @fonts ||= {}
    @font_family ||= ''
    @font_files ||= {}
    @font_style ||= ''
    @font_size ||= 12
    @font_size_pt ||= 12
    @header_width ||= 0
    @header_logo ||= ""
    @header_logo_width ||= 30
    @header_title ||= ""
    @header_string ||= ""
    @images ||= {}
    @img_scale ||= 1
    @in_footer ||= false
    @is_unicode = unicode
    @lasth ||= 0
    @links ||= []
    @listordered ||= false
    @listcount ||= 0
    @lispacer ||= ""
    @n ||= 2
    @offsets ||= []
    @orientation_changes ||= []
    @page ||= 0
    @page_links ||= {}
    @pages ||= []
    @pdf_version ||= "1.3"
    @prevfill_color ||= [255,255,255]
    @prevtext_color ||= [0,0,0]
    @print_header ||= false
    @print_footer ||= false
    @state ||= 0
    @tableborder ||= 0
    @tdbegin ||= false
    @tdwidth ||= 0
    @tdheight ||= 0
    @tdalign ||= "L"
    @tdfill ||= 0
    @tempfontsize ||= 10
    @text_color ||= '0 g'
    @underline ||= false
    @ws ||= 0

    #Standard Unicode fonts
    @core_fonts = {
    'courier'=>'Courier',
    'courierB'=>'Courier-Bold',
    'courierI'=>'Courier-Oblique',
    'courierBI'=>'Courier-BoldOblique',
    'helvetica'=>'Helvetica',
    'helveticaB'=>'Helvetica-Bold',
    'helveticaI'=>'Helvetica-Oblique',
    'helveticaBI'=>'Helvetica-BoldOblique',
    'times'=>'Times-Roman',
    'timesB'=>'Times-Bold',
    'timesI'=>'Times-Italic',
    'timesBI'=>'Times-BoldItalic',
    'symbol'=>'Symbol',
    'zapfdingbats'=>'ZapfDingbats'}

    #Scale factor
    case unit.downcase
      when 'pt' ; @k=1
      when 'mm' ; @k=72/25.4
      when 'cm' ; @k=72/2.54
      when 'in' ; @k=72
      else Error("Incorrect unit: #{unit}")
    end

    #Page format
    if format.is_a?(String)
      # Page formats (45 standard ISO paper formats and 4 american common formats).
      # Paper cordinates are calculated in this way: (inches# 72) where (1 inch = 2.54 cm)
      case (format.upcase)
        when  '4A0' ; format = [4767.87,6740.79]
        when  '2A0' ; format = [3370.39,4767.87]
        when  'A0' ; format = [2383.94,3370.39]
        when  'A1' ; format = [1683.78,2383.94]
        when  'A2' ; format = [1190.55,1683.78]
        when  'A3' ; format = [841.89,1190.55]
        when  'A4' ; format = [595.28,841.89] # ; default
        when  'A5' ; format = [419.53,595.28]
        when  'A6' ; format = [297.64,419.53]
        when  'A7' ; format = [209.76,297.64]
        when  'A8' ; format = [147.40,209.76]
        when  'A9' ; format = [104.88,147.40]
        when  'A10' ; format = [73.70,104.88]
        when  'B0' ; format = [2834.65,4008.19]
        when  'B1' ; format = [2004.09,2834.65]
        when  'B2' ; format = [1417.32,2004.09]
        when  'B3' ; format = [1000.63,1417.32]
        when  'B4' ; format = [708.66,1000.63]
        when  'B5' ; format = [498.90,708.66]
        when  'B6' ; format = [354.33,498.90]
        when  'B7' ; format = [249.45,354.33]
        when  'B8' ; format = [175.75,249.45]
        when  'B9' ; format = [124.72,175.75]
        when  'B10' ; format = [87.87,124.72]
        when  'C0' ; format = [2599.37,3676.54]
        when  'C1' ; format = [1836.85,2599.37]
        when  'C2' ; format = [1298.27,1836.85]
        when  'C3' ; format = [918.43,1298.27]
        when  'C4' ; format = [649.13,918.43]
        when  'C5' ; format = [459.21,649.13]
        when  'C6' ; format = [323.15,459.21]
        when  'C7' ; format = [229.61,323.15]
        when  'C8' ; format = [161.57,229.61]
        when  'C9' ; format = [113.39,161.57]
        when  'C10' ; format = [79.37,113.39]
        when  'RA0' ; format = [2437.80,3458.27]
        when  'RA1' ; format = [1729.13,2437.80]
        when  'RA2' ; format = [1218.90,1729.13]
        when  'RA3' ; format = [864.57,1218.90]
        when  'RA4' ; format = [609.45,864.57]
        when  'SRA0' ; format = [2551.18,3628.35]
        when  'SRA1' ; format = [1814.17,2551.18]
        when  'SRA2' ; format = [1275.59,1814.17]
        when  'SRA3' ; format = [907.09,1275.59]
        when  'SRA4' ; format = [637.80,907.09]
        when  'LETTER' ; format = [612.00,792.00]
        when  'LEGAL' ; format = [612.00,1008.00]
        when  'EXECUTIVE' ; format = [521.86,756.00]
        when  'FOLIO' ; format = [612.00,936.00]
        #else then Error("Unknown page format: #{format}"
      end
      @fw_pt = format[0]
      @fh_pt = format[1]
    else
      @fw_pt = format[0]*@k
      @fh_pt = format[1]*@k
    end

    @fw = @fw_pt/@k
    @fh = @fh_pt/@k

    #Page orientation
    orientation = orientation.downcase
    if orientation == 'p' or orientation == 'portrait'
      @def_orientation = 'P'
      @w_pt = @fw_pt
      @h_pt = @fh_pt
    elsif orientation == 'l' or orientation == 'landscape'
      @def_orientation = 'L'
      @w_pt = @fh_pt
      @h_pt = @fw_pt
    else
      Error("Incorrect orientation: #{orientation}")
    end

    @cur_orientation = @def_orientation
    @w = @w_pt/@k
    @h = @h_pt/@k
    #Page margins (1 cm)
    margin = 28.35/@k
    SetMargins(margin, margin)
    #Interior cell margin (1 mm)
    @c_margin = margin / 10
    #Line width (0.2 mm)
    @line_width = 0.567 / @k
    #Automatic page break
    SetAutoPageBreak(true, 2 * margin)
    #Full width display mode
    SetDisplayMode('fullwidth')
    #Compression
    SetCompression(true)
    #Set default PDF version number
    @pdf_version = "1.3"

    @encoding = encoding
    @b = 0
    @i = 0
    @u = 0
    @href = ''
    @fontlist = ["arial", "times", "courier", "helvetica", "symbol"]
    @issetfont = false
    @issetcolor = false

    SetFillColor(200, 200, 200, true)
    SetTextColor(0, 0, 0, true)
  end

  #
  # Set the image scale.
  # @param float :scale image scale.
  # @author Nicola Asuni
  # @since 1.5.2
  #
  def SetImageScale(scale)
    @img_scale = scale;
  end
  alias_method :set_image_scale, :SetImageScale

  #
  # Returns the image scale.
  # @return float image scale.
  # @author Nicola Asuni
  # @since 1.5.2
  #
  def GetImageScale()
    return @img_scale;
  end
  alias_method :get_image_scale, :GetImageScale

  #
  # Returns the page width in units.
  # @return int page width.
  # @author Nicola Asuni
  # @since 1.5.2
  #
  def GetPageWidth()
    return @w;
  end
  alias_method :get_page_width, :GetPageWidth

  #
  # Returns the page height in units.
  # @return int page height.
  # @author Nicola Asuni
  # @since 1.5.2
  #
  def GetPageHeight()
    return @h;
  end
  alias_method :get_page_height, :GetPageHeight

  #
  # Returns the page break margin.
  # @return int page break margin.
  # @author Nicola Asuni
  # @since 1.5.2
  #
  def GetBreakMargin()
    return @b_margin;
  end
  alias_method :get_break_margin, :GetBreakMargin

  #
  # Returns the scale factor (number of points in user unit).
  # @return int scale factor.
  # @author Nicola Asuni
  # @since 1.5.2
  #
  def GetScaleFactor()
    return @k;
  end
  alias_method :get_scale_factor, :GetScaleFactor

  #
  # Defines the left, top and right margins. By default, they equal 1 cm. Call this method to change them.
  # @param float :left Left margin.
  # @param float :top Top margin.
  # @param float :right Right margin. Default value is the left one.
  # @since 1.0
  # @see SetLeftMargin(), SetTopMargin(), SetRightMargin(), SetAutoPageBreak()
  #
  def SetMargins(left, top, right=-1)
    #Set left, top and right margins
    @l_margin = left
    @t_margin = top
    if (right == -1)
      right = left
    end
    @r_margin = right
  end
  alias_method :set_margins, :SetMargins

  #
  # Defines the left margin. The method can be called before creating the first page. If the current abscissa gets out of page, it is brought back to the margin.
  # @param float :margin The margin.
  # @since 1.4
  # @see SetTopMargin(), SetRightMargin(), SetAutoPageBreak(), SetMargins()
  #
  def SetLeftMargin(margin)
    #Set left margin
    @l_margin = margin
    if ((@page>0) and (@x < margin))
      @x = margin
    end
  end
  alias_method :set_left_margin, :SetLeftMargin

  #
  # Defines the top margin. The method can be called before creating the first page.
  # @param float :margin The margin.
  # @since 1.5
  # @see SetLeftMargin(), SetRightMargin(), SetAutoPageBreak(), SetMargins()
  #
  def SetTopMargin(margin)
    #Set top margin
    @t_margin = margin
  end
  alias_method :set_top_margin, :SetTopMargin

  #
  # Defines the right margin. The method can be called before creating the first page.
  # @param float :margin The margin.
  # @since 1.5
  # @see SetLeftMargin(), SetTopMargin(), SetAutoPageBreak(), SetMargins()
  #
  def SetRightMargin(margin)
    #Set right margin
    @r_margin = margin
  end
  alias_method :set_right_margin, :SetRightMargin

  #
  # Enables or disables the automatic page breaking mode. When enabling, the second parameter is the distance from the bottom of the page that defines the triggering limit. By default, the mode is on and the margin is 2 cm.
  # @param boolean :auto Boolean indicating if mode should be on or off.
  # @param float :margin Distance from the bottom of the page.
  # @since 1.0
  # @see Cell(), MultiCell(), AcceptPageBreak()
  #
  def SetAutoPageBreak(auto, margin=0)
    #Set auto page break mode and triggering margin
    @auto_page_break = auto
    @b_margin = margin
    @page_break_trigger = @h - margin
  end
  alias_method :set_auto_page_break, :SetAutoPageBreak

  #
  # Defines the way the document is to be displayed by the viewer. The zoom level can be set: pages can be displayed entirely on screen, occupy the full width of the window, use real size, be scaled by a specific zooming factor or use viewer default (configured in the Preferences menu of Acrobat). The page layout can be specified too: single at once, continuous display, two columns or viewer default. By default, documents use the full width mode with continuous display.
  # @param mixed :zoom The zoom to use. It can be one of the following string values or a number indicating the zooming factor to use. <ul><li>fullpage: displays the entire page on screen </li><li>fullwidth: uses maximum width of window</li><li>real: uses real size (equivalent to 100% zoom)</li><li>default: uses viewer default mode</li></ul>
  # @param string :layout The page layout. Possible values are:<ul><li>single: displays one page at once</li><li>continuous: displays pages continuously (default)</li><li>two: displays two pages on two columns</li><li>default: uses viewer default mode</li></ul>
  # @since 1.2
  #
  def SetDisplayMode(zoom, layout = 'continuous')
    #Set display mode in viewer
    if (zoom == 'fullpage' or zoom == 'fullwidth' or zoom == 'real' or zoom == 'default' or !zoom.is_a?(String))
      @zoom_mode = zoom
    else
      Error("Incorrect zoom display mode: #{zoom}")
    end
    if (layout == 'single' or layout == 'continuous' or layout == 'two' or layout == 'default')
      @layout_mode = layout
    else
      Error("Incorrect layout display mode: #{layout}")
    end
  end
  alias_method :set_display_mode, :SetDisplayMode

  #
  # Activates or deactivates page compression. When activated, the internal representation of each page is compressed, which leads to a compression ratio of about 2 for the resulting document. Compression is on by default.
  # Note: the Zlib extension is required for this feature. If not present, compression will be turned off.
  # @param boolean :compress Boolean indicating if compression must be enabled.
  # @since 1.4
  #
  def SetCompression(compress)
    #Set page compression
    if (respond_to?('gzcompress'))
      @compress = compress
    else
      @compress = false
    end
  end
  alias_method :set_compression, :SetCompression

  #
  # Defines the title of the document.
  # @param string :title The title.
  # @since 1.2
  # @see SetAuthor(), SetCreator(), SetKeywords(), SetSubject()
  #
  def SetTitle(title)
    #Title of document
    @title = title
  end
  alias_method :set_title, :SetTitle

  #
  # Defines the subject of the document.
  # @param string :subject The subject.
  # @since 1.2
  # @see SetAuthor(), SetCreator(), SetKeywords(), SetTitle()
  #
  def SetSubject(subject)
    #Subject of document
    @subject = subject
  end
  alias_method :set_subject, :SetSubject

  #
  # Defines the author of the document.
  # @param string :author The name of the author.
  # @since 1.2
  # @see SetCreator(), SetKeywords(), SetSubject(), SetTitle()
  #
  def SetAuthor(author)
    #Author of document
    @author = author
  end
  alias_method :set_author, :SetAuthor

  #
  # Associates keywords with the document, generally in the form 'keyword1 keyword2 ...'.
  # @param string :keywords The list of keywords.
  # @since 1.2
  # @see SetAuthor(), SetCreator(), SetSubject(), SetTitle()
  #
  def SetKeywords(keywords)
    #Keywords of document
    @keywords = keywords
  end
  alias_method :set_keywords, :SetKeywords

  #
  # Defines the creator of the document. This is typically the name of the application that generates the PDF.
  # @param string :creator The name of the creator.
  # @since 1.2
  # @see SetAuthor(), SetKeywords(), SetSubject(), SetTitle()
  #
  def SetCreator(creator)
    #Creator of document
    @creator = creator
  end
  alias_method :set_creator, :SetCreator

  #
  # Defines an alias for the total number of pages. It will be substituted as the document is closed.<br />
  # <b>Example:</b><br />
  # <pre>
  # class PDF extends TCPDF {
  #   def Footer()
  #     #Go to 1.5 cm from bottom
  #     SetY(-15);
  #     #Select Arial italic 8
  #     SetFont('Arial','I',8);
  #     #Print current and total page numbers
  #     Cell(0,10,'Page '.PageNo().'/{nb}',0,0,'C');
  #   end
  # }
  # :pdf=new PDF();
  # :pdf->alias_nb_pages();
  # </pre>
  # @param string :alias The alias. Default valuenb}.
  # @since 1.4
  # @see PageNo(), Footer()
  #
  def alias_nb_pages(alias_nb ='{nb}')
    #Define an alias for total number of pages
    @alias_nb_pages = escapetext(alias_nb)
  end

  #
  # This method is automatically called in case of fatal error; it simply outputs the message and halts the execution. An inherited class may override it to customize the error handling but should always halt the script, or the resulting document would probably be invalid.
  # 2004-06-11 :: Nicola Asuni : changed bold tag with strong
  # @param string :msg The error message
  # @since 1.0
  #
  def Error(msg)
    #Fatal error
    raise ("TCPDF error: #{msg}")
  end
  alias_method :error, :Error

  #
  # This method begins the generation of the PDF document. It is not necessary to call it explicitly because AddPage() does it automatically.
  # Note: no page is created by this method
  # @since 1.0
  # @see AddPage(), Close()
  #
  def Open()
    #Begin document
    @state = 1
  end
  # alias_method :open, :Open

  #
  # Terminates the PDF document. It is not necessary to call this method explicitly because Output() does it automatically. If the document contains no page, AddPage() is called to prevent from getting an invalid document.
  # @since 1.0
  # @see Open(), Output()
  #
  def Close()
    #Terminate document
    if (@state==3)
      return;
    end
    if (@page==0)
      AddPage();
    end
    #Page footer
    @in_footer=true;
    Footer();
    @in_footer=false;
    #Close page
    endpage();
    #Close document
    enddoc();
  end
  # alias_method :close, :Close

  #
  # Adds a new page to the document. If a page is already present, the Footer() method is called first to output the footer. Then the page is added, the current position set to the top-left corner according to the left and top margins, and Header() is called to display the header.
  # The font which was set before calling is automatically restored. There is no need to call SetFont() again if you want to continue with the same font. The same is true for colors and line width.
  # The origin of the coordinate system is at the top-left corner and increasing ordinates go downwards.
  # @param string :orientation Page orientation. Possible values are (case insensitive):<ul><li>P or Portrait</li><li>L or Landscape</li></ul> The default value is the one passed to the constructor.
  # @since 1.0
  # @see TCPDF(), Header(), Footer(), SetMargins()
  #
  def AddPage(orientation='')
    #Start a new page
    if (@state==0)
      Open();
    end
    family=@font_family;
    style=@font_style + (@underline ? 'U' : '');
    size=@font_size_pt;
    lw=@line_width;
    dc=@draw_color;
    fc=@fill_color;
    tc=@text_color;
    cf=@color_flag;
    if (@page>0)
      #Page footer
      @in_footer=true;
      Footer();
      @in_footer=false;
      #Close page
      endpage();
    end
    #Start new page
    beginpage(orientation);
    #Set line cap style to square
    out('2 J');
    #Set line width
    @line_width = lw;
    out(sprintf('%.2f w', lw*@k));
    #Set font
    if (family)
      SetFont(family, style, size);
    end
    #Set colors
    @draw_color = dc;
    if (dc!='0 G')
      out(dc);
    end
    @fill_color = fc;
    if (fc!='0 g')
      out(fc);
    end
    @text_color = tc;
    @color_flag = cf;
    #Page header
    Header();
    #Restore line width
    if (@line_width != lw)
      @line_width = lw;
      out(sprintf('%.2f w', lw*@k));
    end
    #Restore font
    if (family)
      SetFont(family, style, size);
    end
    #Restore colors
    if (@draw_color != dc)
      @draw_color = dc;
      out(dc);
    end
    if (@fill_color != fc)
      @fill_color = fc;
      out(fc);
    end
    @text_color = tc;
    @color_flag = cf;
  end
    alias_method :add_page, :AddPage

  #
  # Rotate object.
  # @param float :angle angle in degrees for counter-clockwise rotation
  # @param int :x abscissa of the rotation center. Default is current x position
  # @param int :y ordinate of the rotation center. Default is current y position
  #
  def Rotate(angle, x="", y="")

    if (x == '')
      x = @x;
    end

    if (y == '')
      y = @y;
    end

    if (@rtl)
      x = @w - x;
      angle = -@angle;
    end

    y = (@h - y) * @k;
    x *= @k;

    # calculate elements of transformation matrix
    tm = []
    tm[0] = ::Math::cos(deg2rad(angle));
    tm[1] = ::Math::sin(deg2rad(angle));
    tm[2] = -tm[1];
    tm[3] = tm[0];
    tm[4] = x + tm[1] * y - tm[0] * x;
    tm[5] = y - tm[0] * y - tm[1] * x;

    # generate the transformation matrix
    Transform(tm);
  end
    alias_method :rotate, :Rotate

  #
  # Starts a 2D tranformation saving current graphic state.
  # This function must be called before scaling, mirroring, translation, rotation and skewing.
  # Use StartTransform() before, and StopTransform() after the transformations to restore the normal behavior.
  #
  def StartTransform
    out('q');
  end
    alias_method :start_transform, :StartTransform

  #
  # Stops a 2D tranformation restoring previous graphic state.
  # This function must be called after scaling, mirroring, translation, rotation and skewing.
  # Use StartTransform() before, and StopTransform() after the transformations to restore the normal behavior.
  #
  def StopTransform
    out('Q');
  end
    alias_method :stop_transform, :StopTransform

  #
  # Apply graphic transformations.
  # @since 2.1.000 (2008-01-07)
  # @see StartTransform(), StopTransform()
  #
  def Transform(tm)
    x = out(sprintf('%.3f %.3f %.3f %.3f %.3f %.3f cm', tm[0], tm[1], tm[2], tm[3], tm[4], tm[5]));
  end
    alias_method :transform, :Transform

  #
   # Set header data.
  # @param string :ln header image logo
  # @param string :lw header image logo width in mm
  # @param string :ht string to print as title on document header
  # @param string :hs string to print on document header
  #
  def SetHeaderData(ln="", lw=0, ht="", hs="")
    @header_logo = ln || ""
    @header_logo_width = lw || 0
    @header_title = ht || ""
    @header_string = hs || ""
  end
    alias_method :set_header_data, :SetHeaderData

  #
   # Set header margin.
  # (minimum distance between header and top page margin)
  # @param int :hm distance in millimeters
  #
  def SetHeaderMargin(hm=10)
    @header_margin = hm;
  end
    alias_method :set_header_margin, :SetHeaderMargin

  #
   # Set footer margin.
  # (minimum distance between footer and bottom page margin)
  # @param int :fm distance in millimeters
  #
  def SetFooterMargin(fm=10)
    @footer_margin = fm;
  end
    alias_method :set_footer_margin, :SetFooterMargin

  #
   # Set a flag to print page header.
  # @param boolean :val set to true to print the page header (default), false otherwise.
  #
  def SetPrintHeader(val=true)
    @print_header = val;
  end
    alias_method :set_print_header, :SetPrintHeader

  #
   # Set a flag to print page footer.
  # @param boolean :value set to true to print the page footer (default), false otherwise.
  #
  def SetPrintFooter(val=true)
    @print_footer = val;
  end
    alias_method :set_print_footer, :SetPrintFooter

  #
   # This method is used to render the page header.
   # It is automatically called by AddPage() and could be overwritten in your own inherited class.
  #
  def Header()
    if (@print_header)
      if (@original_l_margin.nil?)
        @original_l_margin = @l_margin;
      end
      if (@original_r_margin.nil?)
        @original_r_margin = @r_margin;
      end

      #set current position
      SetXY(@original_l_margin, @header_margin);

      if ((@header_logo) and (@header_logo != @@k_blank_image))
        Image(@header_logo, @original_l_margin, @header_margin, @header_logo_width);
      else
        @img_rb_y = GetY();
      end

      cell_height = ((@@k_cell_height_ratio * @header_font[2]) / @k).round(2)

      header_x = @original_l_margin + (@header_logo_width * 1.05); #set left margin for text data cell

      # header title
      SetFont(@header_font[0], 'B', @header_font[2] + 1);
      SetX(header_x);
      Cell(@header_width, cell_height, @header_title, 0, 1, 'L');

      # header string
      SetFont(@header_font[0], @header_font[1], @header_font[2]);
      SetX(header_x);
      MultiCell(@header_width, cell_height, @header_string, 0, 'L', 0);

      # print an ending header line
      if (@header_width)
        #set style for cell border
        SetLineWidth(0.3);
        SetDrawColor(0, 0, 0);
        SetY(1 + (@img_rb_y > GetY() ? @img_rb_y : GetY()));
        SetX(@original_l_margin);
        Cell(0, 0, '', 'T', 0, 'C');
      end

      #restore position
      SetXY(@original_l_margin, @t_margin);
    end
  end
    alias_method :header, :Header

  #
   # This method is used to render the page footer.
   # It is automatically called by AddPage() and could be overwritten in your own inherited class.
  #
  def Footer()
    if (@print_footer)

      if (@original_l_margin.nil?)
        @original_l_margin = @l_margin;
      end
      if (@original_r_margin.nil?)
        @original_r_margin = @r_margin;
      end

      #set font
      SetFont(@footer_font[0], @footer_font[1] , @footer_font[2]);
      #set style for cell border
      line_width = 0.3;
      SetLineWidth(line_width);
      SetDrawColor(0, 0, 0);

      footer_height = ((@@k_cell_height_ratio * @footer_font[2]) / @k).round; #footer height, was , 2)
      #get footer y position
      footer_y = @h - @footer_margin - footer_height;
      #set current position
      SetXY(@original_l_margin, footer_y);
      SetXY(@original_l_margin, footer_y);

      #Print page number
      Cell(0, footer_height, @l['w_page'] + " " + PageNo().to_s + ' / {nb}', 'T', 0, 'R');
    end
  end
    alias_method :footer, :Footer

  #
  # Returns the current page number.
  # @return int page number
  # @since 1.0
  # @see alias_nb_pages()
  #
  def PageNo()
    #Get current page number
    return @page;
  end
  alias_method :page_no, :PageNo

  #
  # Defines the color used for all drawing operations (lines, rectangles and cell borders). It can be expressed in RGB components or gray scale. The method can be called before the first page is created and the value is retained from page to page.
  # @param int :r If g et b are given, red component; if not, indicates the gray level. Value between 0 and 255
  # @param int :g Green component (between 0 and 255)
  # @param int :b Blue component (between 0 and 255)
  # @since 1.3
  # @see SetFillColor(), SetTextColor(), Line(), Rect(), Cell(), MultiCell()
  #
  def SetDrawColor(r, g=-1, b=-1)
    #Set color for all stroking operations
    if ((r==0 and g==0 and b==0) or g==-1)
      @draw_color=sprintf('%.3f G', r/255.0);
    else
      @draw_color=sprintf('%.3f %.3f %.3f RG', r/255.0, g/255.0, b/255.0);
    end
    if (@page>0)
      out(@draw_color);
    end
  end
  alias_method :set_draw_color, :SetDrawColor

  #
  # Defines the color used for all filling operations (filled rectangles and cell backgrounds). It can be expressed in RGB components or gray scale. The method can be called before the first page is created and the value is retained from page to page.
  # @param int :r If g et b are given, red component; if not, indicates the gray level. Value between 0 and 255
  # @param int :g Green component (between 0 and 255)
  # @param int :b Blue component (between 0 and 255)
  # @param boolean :storeprev if true stores the RGB array on :prevfill_color variable.
  # @since 1.3
  # @see SetDrawColor(), SetTextColor(), Rect(), Cell(), MultiCell()
  #
  def SetFillColor(r, g=-1, b=-1, storeprev=false)
    #Set color for all filling operations
    if ((r==0 and g==0 and b==0) or g==-1)
      @fill_color=sprintf('%.3f g', r/255.0);
    else
      @fill_color=sprintf('%.3f %.3f %.3f rg', r/255.0, g/255.0, b/255.0);
    end
    @color_flag=(@fill_color!=@text_color);
    if (@page>0)
      out(@fill_color);
    end
    if (storeprev)
      # store color as previous value
      @prevfill_color = [r, g, b]
    end
  end
  alias_method :set_fill_color, :SetFillColor

  # This hasn't been ported from tcpdf, it's a variation on SetTextColor for setting cmyk colors
  def SetCmykFillColor(c, m, y, k, storeprev=false)
    #Set color for all filling operations
    @fill_color=sprintf('%.3f %.3f %.3f %.3f k', c, m, y, k);
    @color_flag=(@fill_color!=@text_color);
    if (storeprev)
      # store color as previous value
      @prevtext_color = [c, m, y, k]
    end
    if (@page>0)
      out(@fill_color);
    end
  end
  alias_method :set_cmyk_fill_color, :SetCmykFillColor

  #
  # Defines the color used for text. It can be expressed in RGB components or gray scale. The method can be called before the first page is created and the value is retained from page to page.
  # @param int :r If g et b are given, red component; if not, indicates the gray level. Value between 0 and 255
  # @param int :g Green component (between 0 and 255)
  # @param int :b Blue component (between 0 and 255)
  # @param boolean :storeprev if true stores the RGB array on :prevtext_color variable.
  # @since 1.3
  # @see SetDrawColor(), SetFillColor(), Text(), Cell(), MultiCell()
  #
  def SetTextColor(r, g=-1, b=-1, storeprev=false)
    #Set color for text
    if ((r==0 and :g==0 and :b==0) or :g==-1)
      @text_color=sprintf('%.3f g', r/255.0);
    else
      @text_color=sprintf('%.3f %.3f %.3f rg', r/255.0, g/255.0, b/255.0);
    end
    @color_flag=(@fill_color!=@text_color);
    if (storeprev)
      # store color as previous value
      @prevtext_color = [r, g, b]
    end
  end
  alias_method :set_text_color, :SetTextColor

  # This hasn't been ported from tcpdf, it's a variation on SetTextColor for setting cmyk colors
  def SetCmykTextColor(c, m, y, k, storeprev=false)
    #Set color for text
    @text_color=sprintf('%.3f %.3f %.3f %.3f k', c, m, y, k);
    @color_flag=(@fill_color!=@text_color);
    if (storeprev)
      # store color as previous value
      @prevtext_color = [c, m, y, k]
    end
  end
  alias_method :set_cmyk_text_color, :SetCmykTextColor

  #
  # Returns the length of a string in user unit. A font must be selected.<br>
  # Support UTF-8 Unicode [Nicola Asuni, 2005-01-02]
  # @param string :s The string whose length is to be computed
  # @return int
  # @since 1.2
  #
  def GetStringWidth(s)
    #Get width of a string in the current font
    s = s.to_s;
    cw = @current_font['cw']
    w = 0;
    if (@is_unicode)
      unicode = UTF8StringToArray(s);
      unicode.each do |char|
        if (!cw[char].nil?)
          w += cw[char];
        # This should not happen. UTF8StringToArray should guarentee the array is ascii values.
        # elsif (c!cw[char[0]].nil?)
        #   w += cw[char[0]];
        #         elsif (!cw[char.chr].nil?)
        #           w += cw[char.chr];
        elsif (!@current_font['desc']['MissingWidth'].nil?)
          w += @current_font['desc']['MissingWidth']; # set default size
        else
          w += 500;
        end
      end
    else
      s.each_byte do |c|
        if cw[c]
          w += cw[c];
        elsif cw[?c]
          w += cw[?c]
        end
      end
    end
    return (w * @font_size / 1000.0);
  end
  alias_method :get_string_width, :GetStringWidth

  #
  # Defines the line width. By default, the value equals 0.2 mm. The method can be called before the first page is created and the value is retained from page to page.
  # @param float :width The width.
  # @since 1.0
  # @see Line(), Rect(), Cell(), MultiCell()
  #
  def SetLineWidth(width)
    #Set line width
    @line_width = width;
    if (@page>0)
      out(sprintf('%.2f w', width*@k));
    end
  end
  alias_method :set_line_width, :SetLineWidth

  #
  # Draws a line between two points.
  # @param float :x1 Abscissa of first point
  # @param float :y1 Ordinate of first point
  # @param float :x2 Abscissa of second point
  # @param float :y2 Ordinate of second point
  # @since 1.0
  # @see SetLineWidth(), SetDrawColor()
  #
  def Line(x1, y1, x2, y2)
    #Draw a line
    out(sprintf('%.2f %.2f m %.2f %.2f l S', x1 * @k, (@h - y1) * @k, x2 * @k, (@h - y2) * @k));
  end
  alias_method :line, :Line

  def Circle(mid_x, mid_y, radius, style='')
    mid_y = (@h-mid_y)*@k
    out(sprintf("q\n")) # postscript content in pdf
    # init line type etc. with /GSD gs G g (grey) RG rg (RGB) w=line witdh etc.
    out(sprintf("1 j\n")) # line join
    # translate ("move") circle to mid_y, mid_y
    out(sprintf("1 0 0 1 %f %f cm", mid_x, mid_y))
    kappa = 0.5522847498307933984022516322796
    # Quadrant 1
    x_s = 0.0 # 12 o'clock
    y_s = 0.0 + radius
    x_e = 0.0 + radius # 3 o'clock
    y_e = 0.0
    out(sprintf("%f %f m\n", x_s, y_s)) # move to 12 o'clock
    # cubic bezier control point 1, start height and kappa * radius to the right
    bx_e1 = x_s + (radius * kappa)
    by_e1 = y_s
    # cubic bezier control point 2, end and kappa * radius above
    bx_e2 = x_e
    by_e2 = y_e + (radius * kappa)
    # draw cubic bezier from current point to x_e/y_e with bx_e1/by_e1 and bx_e2/by_e2 as bezier control points
    out(sprintf("%f %f %f %f %f %f c\n", bx_e1, by_e1, bx_e2, by_e2, x_e, y_e))
    # Quadrant 2
    x_s = x_e
    y_s = y_e # 3 o'clock
    x_e = 0.0
    y_e = 0.0 - radius # 6 o'clock
    bx_e1 = x_s # cubic bezier point 1
    by_e1 = y_s - (radius * kappa)
    bx_e2 = x_e + (radius * kappa) # cubic bezier point 2
    by_e2 = y_e
    out(sprintf("%f %f %f %f %f %f c\n", bx_e1, by_e1, bx_e2, by_e2, x_e, y_e))
    # Quadrant 3
    x_s = x_e
    y_s = y_e # 6 o'clock
    x_e = 0.0 - radius
    y_e = 0.0 # 9 o'clock
    bx_e1 = x_s - (radius * kappa) # cubic bezier point 1
    by_e1 = y_s
    bx_e2 = x_e # cubic bezier point 2
    by_e2 = y_e - (radius * kappa)
    out(sprintf("%f %f %f %f %f %f c\n", bx_e1, by_e1, bx_e2, by_e2, x_e, y_e))
    # Quadrant 4
    x_s = x_e
    y_s = y_e # 9 o'clock
    x_e = 0.0
    y_e = 0.0 + radius # 12 o'clock
    bx_e1 = x_s # cubic bezier point 1
    by_e1 = y_s + (radius * kappa)
    bx_e2 = x_e - (radius * kappa) # cubic bezier point 2
    by_e2 = y_e
    out(sprintf("%f %f %f %f %f %f c\n", bx_e1, by_e1, bx_e2, by_e2, x_e, y_e))
    if style=='F'
        op='f'
    elsif style=='FD' or style=='DF'
        op='b'
    else
        op='s'
    end
    out(sprintf("#{op}\n")) # stroke circle, do not fill and close path
    # for filling etc. b, b*, f, f*
    out(sprintf("Q\n")) # finish postscript in PDF
  end
  alias_method :circle, :Circle

  #
  # Outputs a rectangle. It can be drawn (border only), filled (with no border) or both.
  # @param float :x Abscissa of upper-left corner
  # @param float :y Ordinate of upper-left corner
  # @param float :w Width
  # @param float :h Height
  # @param string :style Style of rendering. Possible values are:<ul><li>D or empty string: draw (default)</li><li>F: fill</li><li>DF or FD: draw and fill</li></ul>
  # @since 1.0
  # @see SetLineWidth(), SetDrawColor(), SetFillColor()
  #
  def Rect(x, y, w, h, style='')
    #Draw a rectangle
    if (style=='F')
      op='f';
    elsif (style=='FD' or style=='DF')
      op='B';
    else
      op='S';
    end
    out(sprintf('%.2f %.2f %.2f %.2f re %s', x * @k, (@h - y) * @k, w * @k, -h * @k, op));
  end
  alias_method :rect, :Rect

  #
  # Imports a TrueType or Type1 font and makes it available. It is necessary to generate a font definition file first with the makefont.rb utility. The definition file (and the font file itself when embedding) must be present either in the current directory or in the one indicated by FPDF_FONTPATH if the constant is defined. If it could not be found, the error "Could not include font definition file" is generated.
  # Support UTF-8 Unicode [Nicola Asuni, 2005-01-02].
  # <b>Example</b>:<br />
  # <pre>
  # :pdf->AddFont('Comic','I');
  # # is equivalent to:
  # :pdf->AddFont('Comic','I','comici.rb');
  # </pre>
  # @param string :family Font family. The name can be chosen arbitrarily. If it is a standard family name, it will override the corresponding font.
  # @param string :style Font style. Possible values are (case insensitive):<ul><li>empty string: regular (default)</li><li>B: bold</li><li>I: italic</li><li>BI or IB: bold italic</li></ul>
  # @param string :file The font definition file. By default, the name is built from the family and style, in lower case with no space.
  # @since 1.5
  # @see SetFont()
  #
  def AddFont(family, style='', file='')
    if (family.empty?)
      return;
    end

    #Add a TrueType or Type1 font
    family = family.downcase
    if ((!@is_unicode) and (family == 'arial'))
      family = 'helvetica';
    end

    style=style.upcase
    style=style.gsub('U','');
    if (style == 'IB')
      style = 'BI';
    end

    fontkey = family + style;
    # check if the font has been already added
    if !@fonts[fontkey].nil?
      return;
    end

    if (file=='')
      file = family.gsub(' ', '') + style.downcase + '.rb';
    end
    font_file_name = getfontpath(file)
    if (font_file_name.nil?)
      # try to load the basic file without styles
      file = family.gsub(' ', '') + '.rb';
      font_file_name = getfontpath(file)
    end
    if font_file_name.nil?
      Error("Could not find font #{file}.")
    end
    require(getfontpath(file))
    font_desc = TCPDFFontDescriptor.font(file)

    if (font_desc[:name].nil? and @@fpdf_charwidths.nil?)
      Error('Could not include font definition file');
    end

    i = @fonts.length+1;
    if (@is_unicode)
      @fonts[fontkey] = {'i' => i, 'type' => font_desc[:type], 'name' => font_desc[:name], 'desc' => font_desc[:desc], 'up' => font_desc[:up], 'ut' => font_desc[:ut], 'cw' => font_desc[:cw], 'enc' => font_desc[:enc], 'file' => font_desc[:file], 'ctg' => font_desc[:ctg], 'cMap' => font_desc[:cMap], 'registry' => font_desc[:registry]}
      @@fpdf_charwidths[fontkey] = font_desc[:cw];
    else
      @fonts[fontkey]={'i' => i, 'type'=>'core', 'name'=>@core_fonts[fontkey], 'up'=>-100, 'ut'=>50, 'cw' => font_desc[:cw]}
      @@fpdf_charwidths[fontkey] = font_desc[:cw];
    end

    if (!font_desc[:diff].nil? and (!font_desc[:diff].empty?))
      #Search existing encodings
      d=0;
      nb=@diffs.length;
      1.upto(nb) do |i|
        if (@diffs[i]== font_desc[:diff])
          d = i;
          break;
        end
      end
      if (d==0)
        d = nb+1;
        @diffs[d] = font_desc[:diff];
      end
      @fonts[fontkey]['diff'] = d;
    end
    if (font_desc[:file] and font_desc[:file].length > 0)
      if (font_desc[:type] == "TrueType") or (font_desc[:type] == "TrueTypeUnicode")
        @font_files[font_desc[:file]] = {'length1' => font_desc[:originalsize]}
      else
        @font_files[font_desc[:file]] = {'length1' => font_desc[:size1], 'length2' => font_desc[:size2]}
      end
    end
  end
  alias_method :add_font, :AddFont

  #
  # Sets the font used to print character strings. It is mandatory to call this method at least once before printing text or the resulting document would not be valid.
  # The font can be either a standard one or a font added via the AddFont() method. Standard fonts use Windows encoding cp1252 (Western Europe).
  # The method can be called before the first page is created and the font is retained from page to page.
  # If you just wish to change the current font size, it is simpler to call SetFontSize().
  # Note: for the standard fonts, the font metric files must be accessible. There are three possibilities for this:<ul><li>They are in the current directory (the one where the running script lies)</li><li>They are in one of the directories defined by the include_path parameter</li><li>They are in the directory defined by the FPDF_FONTPATH constant</li></ul><br />
  # Example for the last case (note the trailing slash):<br />
  # <pre>
  # define('FPDF_FONTPATH','/home/www/font/');
  # require('tcpdf.rb');
  #
  # #Times regular 12
  # :pdf->SetFont('Times');
  # #Arial bold 14
  # :pdf->SetFont('Arial','B',14);
  # #Removes bold
  # :pdf->SetFont('');
  # #Times bold, italic and underlined 14
  # :pdf->SetFont('Times','BIU');
  # </pre><br />
  # If the file corresponding to the requested font is not found, the error "Could not include font metric file" is generated.
  # @param string :family Family font. It can be either a name defined by AddFont() or one of the standard families (case insensitive):<ul><li>Courier (fixed-width)</li><li>Helvetica or Arial (synonymous; sans serif)</li><li>Times (serif)</li><li>Symbol (symbolic)</li><li>ZapfDingbats (symbolic)</li></ul>It is also possible to pass an empty string. In that case, the current family is retained.
  # @param string :style Font style. Possible values are (case insensitive):<ul><li>empty string: regular</li><li>B: bold</li><li>I: italic</li><li>U: underline</li></ul>or any combination. The default value is regular. Bold and italic styles do not apply to Symbol and ZapfDingbats
  # @param float :size Font size in points. The default value is the current size. If no size has been specified since the beginning of the document, the value taken is 12
  # @since 1.0
  # @see AddFont(), SetFontSize(), Cell(), MultiCell(), Write()
  #
  def SetFont(family, style='', size=0)
    # save previous values
    @prevfont_family = @font_family;
    @prevfont_style = @font_style;

    family=family.downcase;
    if (family=='')
      family=@font_family;
    end
    if ((!@is_unicode) and (family == 'arial'))
      family = 'helvetica';
    elsif ((family=="symbol") or (family=="zapfdingbats"))
      style='';
    end

    style=style.upcase;

    if (style.include?('U'))
      @underline=true;
      style= style.gsub('U','');
    else
      @underline=false;
    end
    if (style=='IB')
      style='BI';
    end
    if (size==0)
      size=@font_size_pt;
    end

    # try to add font (if not already added)
    if (@is_unicode)
      AddFont(family, style);
    end

    #Test if font is already selected
    if ((@font_family == family) and (@font_style == style) and (@font_size_pt == size))
      return;
    end

    fontkey = family + style;
    style = '' if (@fonts[fontkey].nil? and !@fonts[family].nil?)

    #Test if used for the first time
    if (@fonts[fontkey].nil?)
      #Check if one of the standard fonts
      if (!@core_fonts[fontkey].nil?)
        if @@fpdf_charwidths[fontkey].nil?
          #Load metric file
          file = family;
          if ((family!='symbol') and (family!='zapfdingbats'))
            file += style.downcase;
          end
          if (getfontpath(file + '.rb').nil?)
            # try to load the basic file without styles
            file = family;
            fontkey = family;
          end
          require(getfontpath(file + '.rb'));
          font_desc = TCPDFFontDescriptor.font(file)
          if ((@is_unicode and ctg.nil?) or ((!@is_unicode) and (@@fpdf_charwidths[fontkey].nil?)) )
            Error("Could not include font metric file [" + fontkey + "]: " + getfontpath(file + ".rb"));
          end
        end
        i = @fonts.length + 1;

        if (@is_unicode)
          @fonts[fontkey] = {'i' => i, 'type' => font_desc[:type], 'name' => font_desc[:name], 'desc' => font_desc[:desc], 'up' => font_desc[:up], 'ut' => font_desc[:ut], 'cw' => font_desc[:cw], 'enc' => font_desc[:enc], 'file' => font_desc[:file], 'ctg' => font_desc[:ctg]}
          @@fpdf_charwidths[fontkey] = font_desc[:cw];
        else
          @fonts[fontkey] = {'i' => i, 'type'=>'core', 'name'=>@core_fonts[fontkey], 'up'=>-100, 'ut'=>50, 'cw' => font_desc[:cw]}
          @@fpdf_charwidths[fontkey] = font_desc[:cw];
        end
      else
        Error('Undefined font: ' + family + ' ' + style);
      end
    end
    #Select it
    @font_family = family;
    @font_style = style;
    @font_size_pt = size;
    @font_size = size / @k;
    @current_font = @fonts[fontkey]; # was & may need deep copy?
    if (@page>0)
      out(sprintf('BT /F%d %.2f Tf ET', @current_font['i'], @font_size_pt));
    end
  end
  alias_method :set_font, :SetFont

  #
  # Defines the size of the current font.
  # @param float :size The size (in points)
  # @since 1.0
  # @see SetFont()
  #
  def SetFontSize(size)
    #Set font size in points
    if (@font_size_pt== size)
      return;
    end
    @font_size_pt = size;
    @font_size = size.to_f / @k;
    if (@page > 0)
      out(sprintf('BT /F%d %.2f Tf ET', @current_font['i'], @font_size_pt));
    end
  end
  alias_method :set_font_size, :SetFontSize

  #
  # Creates a new internal link and returns its identifier. An internal link is a clickable area which directs to another place within the document.<br />
  # The identifier can then be passed to Cell(), Write(), Image() or Link(). The destination is defined with SetLink().
  # @since 1.5
  # @see Cell(), Write(), Image(), Link(), SetLink()
  #
  def AddLink()
    #Create a new internal link
    n=@links.length+1;
    @links[n]=[0,0];
    return n;
  end
  alias_method :add_link, :AddLink

  #
  # Defines the page and position a link points to
  # @param int :link The link identifier returned by AddLink()
  # @param float :y Ordinate of target position; -1 indicates the current position. The default value is 0 (top of page)
  # @param int :page Number of target page; -1 indicates the current page. This is the default value
  # @since 1.5
  # @see AddLink()
  #
  def SetLink(link, y=0, page=-1)
    #Set destination of internal link
    if (y==-1)
      y=@y;
    end
    if (page==-1)
      page=@page;
    end
    @links[link] = [page, y]
  end
  alias_method :set_link, :SetLink

  #
  # Puts a link on a rectangular area of the page. Text or image links are generally put via Cell(), Write() or Image(), but this method can be useful for instance to define a clickable area inside an image.
  # @param float :x Abscissa of the upper-left corner of the rectangle
  # @param float :y Ordinate of the upper-left corner of the rectangle
  # @param float :w Width of the rectangle
  # @param float :h Height of the rectangle
  # @param mixed :link URL or identifier returned by AddLink()
  # @since 1.5
  # @see AddLink(), Cell(), Write(), Image()
  #
  def Link(x, y, w, h, link)
    #Put a link on the page
    @page_links ||= Array.new
    @page_links[@page] ||= Array.new
    @page_links[@page].push([x * @k, @h_pt - y * @k, w * @k, h*@k, link]);
  end
  alias_method :link, :Link

  #
  # Prints a character string. The origin is on the left of the first charcter, on the baseline. This method allows to place a string precisely on the page, but it is usually easier to use Cell(), MultiCell() or Write() which are the standard methods to print text.
  # @param float :x Abscissa of the origin
  # @param float :y Ordinate of the origin
  # @param string :txt String to print
  # @since 1.0
  # @see SetFont(), SetTextColor(), Cell(), MultiCell(), Write()
  #
  def Text(x, y, txt)
    #Output a string
    s=sprintf('BT %.2f %.2f Td (%s) Tj ET', x * @k, (@h-y) * @k, escapetext(txt));
    if (@underline and (txt!=''))
      s += ' ' + dounderline(x, y, txt);
    end
    if (@color_flag)
      s='q ' + @text_color + ' ' + s + ' Q';
    end
    out(s);
  end
  alias_method :text, :Text

  #
  # Whenever a page break condition is met, the method is called, and the break is issued or not depending on the returned value. The default implementation returns a value according to the mode selected by SetAutoPageBreak().<br />
  # This method is called automatically and should not be called directly by the application.<br />
  # <b>Example:</b><br />
  # The method is overriden in an inherited class in order to obtain a 3 column layout:<br />
  # <pre>
  # class PDF extends TCPDF {
  #   var :col=0;
  #
  #   def SetCol(col)
  #     #Move position to a column
  #     @col = col;
  #     :x=10+:col*65;
  #     SetLeftMargin(x);
  #     SetX(x);
  #   end
  #
  #   def AcceptPageBreak()
  #     if (@col<2)
  #       #Go to next column
  #       SetCol(@col+1);
  #       SetY(10);
  #       return false;
  #     end
  #     else
  #       #Go back to first column and issue page break
  #       SetCol(0);
  #       return true;
  #     end
  #   end
  # }
  #
  # :pdf=new PDF();
  # :pdf->Open();
  # :pdf->AddPage();
  # :pdf->SetFont('Arial','',12);
  # for(i=1;:i<=300;:i++)
  #     :pdf->Cell(0,5,"Line :i",0,1);
  # }
  # :pdf->Output();
  # </pre>
  # @return boolean
  # @since 1.4
  # @see SetAutoPageBreak()
  #
  def AcceptPageBreak()
    #Accept automatic page break or not
    return @auto_page_break;
  end
  alias_method :accept_page_break, :AcceptPageBreak

  def BreakThePage?(h)
    if ((@y + h) > @page_break_trigger and !@in_footer and AcceptPageBreak())
      true
    else
      false
    end
  end
  alias_method :break_the_page?, :BreakThePage?
  #
  # Prints a cell (rectangular area) with optional borders, background color and character string. The upper-left corner of the cell corresponds to the current position. The text can be aligned or centered. After the call, the current position moves to the right or to the next line. It is possible to put a link on the text.<br />
  # If automatic page breaking is enabled and the cell goes beyond the limit, a page break is done before outputting.
  # @param float :w Cell width. If 0, the cell extends up to the right margin.
  # @param float :h Cell height. Default value: 0.
  # @param string :txt String to print. Default value: empty string.
  # @param mixed :border Indicates if borders must be drawn around the cell. The value can be either a number:<ul><li>0: no border (default)</li><li>1: frame</li></ul>or a string containing some or all of the following characters (in any order):<ul><li>L: left</li><li>T: top</li><li>R: right</li><li>B: bottom</li></ul>
  # @param int :ln Indicates where the current position should go after the call. Possible values are:<ul><li>0: to the right</li><li>1: to the beginning of the next line</li><li>2: below</li></ul>
  # Putting 1 is equivalent to putting 0 and calling Ln() just after. Default value: 0.
  # @param string :align Allows to center or align the text. Possible values are:<ul><li>L or empty string: left align (default value)</li><li>C: center</li><li>R: right align</li></ul>
  # @param int :fill Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # @param mixed :link URL or identifier returned by AddLink().
  # @since 1.0
  # @see SetFont(), SetDrawColor(), SetFillColor(), SetTextColor(), SetLineWidth(), AddLink(), Ln(), MultiCell(), Write(), SetAutoPageBreak()
  #
  def Cell(w, h=0, txt='', border=0, ln=0, align='', fill=0, link=nil)
    #Output a cell
    k=@k;
    if ((@y + h) > @page_break_trigger and !@in_footer and AcceptPageBreak())
      #Automatic page break
      x = @x;
      ws = @ws;
      if (ws > 0)
        @ws = 0;
        out('0 Tw');
      end
      AddPage(@cur_orientation);
      @x = x;
      if (ws > 0)
        @ws = ws;
        out(sprintf('%.3f Tw', ws * k));
      end
    end
    if (w == 0)
      w = @w - @r_margin - @x;
    end
    s = '';
    if ((fill.to_i == 1) or (border.to_i == 1))
      if (fill.to_i == 1)
        op = (border.to_i == 1) ? 'B' : 'f';
      else
        op = 'S';
      end
      s = sprintf('%.2f %.2f %.2f %.2f re %s ', @x * k, (@h - @y) * k, w * k, -h * k, op);
    end
    if (border.is_a?(String))
      x=@x;
      y=@y;
      if (border.include?('L'))
        s<<sprintf('%.2f %.2f m %.2f %.2f l S ', x*k,(@h-y)*k, x*k,(@h-(y+h))*k);
      end
      if (border.include?('T'))
        s<<sprintf('%.2f %.2f m %.2f %.2f l S ', x*k,(@h-y)*k,(x+w)*k,(@h-y)*k);
      end
      if (border.include?('R'))
        s<<sprintf('%.2f %.2f m %.2f %.2f l S ',(x+w)*k,(@h-y)*k,(x+w)*k,(@h-(y+h))*k);
      end
      if (border.include?('B'))
        s<<sprintf('%.2f %.2f m %.2f %.2f l S ', x*k,(@h-(y+h))*k,(x+w)*k,(@h-(y+h))*k);
      end
    end
    if (txt != '')
      width = GetStringWidth(txt);
      if (align == 'R' || align == 'right')
        dx = w - @c_margin - width;
      elsif (align=='C' || align == 'center')
        dx = (w - width)/2;
      else
        dx = @c_margin;
      end
      if (@color_flag)
        s << 'q ' + @text_color + ' ';
      end
      txt2 = escapetext(txt);
      s<<sprintf('BT %.2f %.2f Td (%s) Tj ET', (@x + dx) * k, (@h - (@y + 0.5 * h + 0.3 * @font_size)) * k, txt2);
      if (@underline)
        s<<' ' + dounderline(@x + dx, @y + 0.5 * h + 0.3 * @font_size, txt);
      end
      if (@color_flag)
        s<<' Q';
      end
      if link && !link.empty?
        Link(@x + dx, @y + 0.5 * h - 0.5 * @font_size, width, @font_size, link);
      end
    end
    if (s)
      out(s);
    end
    @lasth = h;
    if (ln.to_i>0)
      # Go to next line
      @y += h;
      if (ln == 1)
        @x = @l_margin;
      end
    else
      @x += w;
    end
  end
  alias_method :cell, :Cell

  #
  # This method allows printing text with line breaks. They can be automatic (as soon as the text reaches the right border of the cell) or explicit (via the \n character). As many cells as necessary are output, one below the other.<br />
  # Text can be aligned, centered or justified. The cell block can be framed and the background painted.
  # @param float :w Width of cells. If 0, they extend up to the right margin of the page.
  # @param float :h Height of cells.
  # @param string :txt String to print
  # @param mixed :border Indicates if borders must be drawn around the cell block. The value can be either a number:<ul><li>0: no border (default)</li><li>1: frame</li></ul>or a string containing some or all of the following characters (in any order):<ul><li>L: left</li><li>T: top</li><li>R: right</li><li>B: bottom</li></ul>
  # @param string :align Allows to center or align the text. Possible values are:<ul><li>L or empty string: left align</li><li>C: center</li><li>R: right align</li><li>J: justification (default value)</li></ul>
  # @param int :fill Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # @param int :ln Indicates where the current position should go after the call. Possible values are:<ul><li>0: to the right</li><li>1: to the beginning of the next line [DEFAULT]</li><li>2: below</li></ul>
  # @since 1.3
  # @see SetFont(), SetDrawColor(), SetFillColor(), SetTextColor(), SetLineWidth(), Cell(), Write(), SetAutoPageBreak()
  #
  def MultiCell(w, h, txt, border=0, align='J', fill=0, ln=1)

    # save current position
    prevx = @x;
    prevy = @y;

    #Output text with automatic or explicit line breaks

    if (w == 0)
      w = @w - @r_margin - @x;
    end

    wmax = (w - 2 * @c_margin);

    s = txt.gsub("\r", ''); # remove carriage returns
    nb = s.length;

    b=0;
    if (border)
      if (border==1)
        border='LTRB';
        b='LRT';
        b2='LR';
      elsif border.is_a?(String)
        b2='';
        if (border.include?('L'))
          b2<<'L';
        end
        if (border.include?('R'))
          b2<<'R';
        end
        b=(border.include?('T')) ? b2 + 'T' : b2;
      end
    end
    sep=-1;
    to_index=0;
    from_j=0;
    l=0;
    ns=0;
    nl=1;

    while to_index < nb
      #Get next character
      c = s[to_index];
      if c == "\n"[0]
        #Explicit line break
        if @ws > 0
          @ws = 0
          out('0 Tw')
        end
        #Ed Moss - change begin
        end_i = to_index == 0 ? 0 : to_index - 1
        # Changed from s[from_j..to_index] to fix bug reported by Hans Allis.
        from_j = to_index == 0 ? 1 : from_j
        Cell(w, h, s[from_j..end_i], b, 2, align, fill)
        #change end
        to_index += 1
        sep=-1
        from_j=to_index
        l=0
        ns=0
        nl += 1
        b = b2 if border and nl==2
        next
      end
      if (c == " "[0])
        sep = to_index;
        ls = l;
        ns += 1;
      end

      l = GetStringWidth(s[from_j, to_index-from_j]);

      if (l > wmax)
        #Automatic line break
        if (sep == -1)
          if (to_index == from_j)
            to_index += 1;
          end
          if (@ws > 0)
            @ws = 0;
            out('0 Tw');
          end
          Cell(w, h, s[from_j..to_index-1], b, 2, align, fill) # my FPDF version
        else
          if (align=='J' || align=='justify' || align=='justified')
            @ws = (ns>1) ? (wmax-ls)/(ns-1) : 0;
            out(sprintf('%.3f Tw', @ws * @k));
          end
          Cell(w, h, s[from_j..sep], b, 2, align, fill);
          to_index = sep + 1;
        end
        sep=-1;
        from_j = to_index;
        l=0;
        ns=0;
        nl += 1;
        if (border and (nl==2))
          b = b2;
        end
      else
        to_index += 1;
      end
    end
    #Last chunk
    if (@ws>0)
      @ws=0;
      out('0 Tw');
    end
    if (border.is_a?(String) and border.include?('B'))
      b<<'B';
    end
    Cell(w, h, s[from_j, to_index-from_j], b, 2, align, fill);

    # move cursor to specified position
    # since 2007-03-03
    if (ln == 1)
      # go to the beginning of the next line
      @x = @l_margin;
    elsif (ln == 0)
      # go to the top-right of the cell
      @y = prevy;
      @x = prevx + w;
    elsif (ln == 2)
      # go to the bottom-left of the cell
      @x = prevx;
    end
  end
  alias_method :multi_cell, :MultiCell

  #
  # This method prints text from the current position. When the right margin is reached (or the \n character is met) a line break occurs and text continues from the left margin. Upon method exit, the current position is left just at the end of the text. It is possible to put a link on the text.<br />
  # <b>Example:</b><br />
  # <pre>
  # #Begin with regular font
  # :pdf->SetFont('Arial','',14);
  # :pdf->Write(5,'Visit ');
  # #Then put a blue underlined link
  # :pdf->SetTextColor(0,0,255);
  # :pdf->SetFont('','U');
  # :pdf->Write(5,'www.tecnick.com','http://www.tecnick.com');
  # </pre>
  # @param float :h Line height
  # @param string :txt String to print
  # @param mixed :link URL or identifier returned by AddLink()
  # @param int :fill Indicates if the background must be painted (1) or transparent (0). Default value: 0.
  # @since 1.5
  # @see SetFont(), SetTextColor(), AddLink(), MultiCell(), SetAutoPageBreak()
  #
  def Write(h, txt, link=nil, fill=0)

    #Output text in flowing mode
    w = @w - @r_margin - @x;
    wmax = (w - 2 * @c_margin);

    s = txt.gsub("\r", '');
    nb = s.length;

    # handle single space character
    if ((nb==1) and (s == " "))
      @x += GetStringWidth(s);
      return;
    end

    sep=-1;
    i=0;
    j=0;
    l=0;
    nl=1;
    while(i<nb)
      #Get next character
      c = s[i];
      if (c == "\n"[0])
        #Explicit line break
        Cell(w, h, s[j,i-j], 0, 2, '', fill, link);
        i += 1;
        sep = -1;
        j = i;
        l = 0;
        if (nl == 1)
          @x = @l_margin;
          w = @w - @r_margin - @x;
          wmax = (w - 2 * @c_margin);
        end
        nl += 1;
        next
      end
      if (c == " "[0])
        sep= i;
      end
      l = GetStringWidth(s[j, i-j]);
      if (l > wmax)
        #Automatic line break (word wrapping)
        if (sep == -1)
          if (@x > @l_margin)
            #Move to next line
            @x = @l_margin;
            @y += h;
            w=@w - @r_margin - @x;
            wmax=(w - 2 * @c_margin);
            i += 1
            nl += 1
            next
          end
          if (i == j)
            i += 1
          end
          Cell(w, h, s[j, (i-1)], 0, 2, '', fill, link);
        else
          Cell(w, h, s[j, (sep-j)], 0, 2, '', fill, link);
          i = sep+1;
        end
        sep = -1;
        j = i;
        l = 0;
        if (nl==1)
          @x = @l_margin;
          w = @w - @r_margin - @x;
          wmax = (w - 2 * @c_margin);
        end
        nl += 1;
      else
        i += 1;
      end
    end
    #Last chunk
    if (i != j)
      Cell(GetStringWidth(s[j..i]), h, s[j..i], 0, 0, '', fill, link);
    end
  end
  alias_method :write, :Write

  #
  # Puts an image in the page. The upper-left corner must be given. The dimensions can be specified in different ways:<ul><li>explicit width and height (expressed in user unit)</li><li>one explicit dimension, the other being calculated automatically in order to keep the original proportions</li><li>no explicit dimension, in which case the image is put at 72 dpi</li></ul>
  # Supported formats are JPEG and PNG.
  # For JPEG, all flavors are allowed:<ul><li>gray scales</li><li>true colors (24 bits)</li><li>CMYK (32 bits)</li></ul>
  # For PNG, are allowed:<ul><li>gray scales on at most 8 bits (256 levels)</li><li>indexed colors</li><li>true colors (24 bits)</li></ul>
  # but are not supported:<ul><li>Interlacing</li><li>Alpha channel</li></ul>
  # If a transparent color is defined, it will be taken into account (but will be only interpreted by Acrobat 4 and above).<br />
  # The format can be specified explicitly or inferred from the file extension.<br />
  # It is possible to put a link on the image.<br />
  # Remark: if an image is used several times, only one copy will be embedded in the file.<br />
  # @param string :file Name of the file containing the image.
  # @param float :x Abscissa of the upper-left corner.
  # @param float :y Ordinate of the upper-left corner.
  # @param float :w Width of the image in the page. If not specified or equal to zero, it is automatically calculated.
  # @param float :h Height of the image in the page. If not specified or equal to zero, it is automatically calculated.
  # @param string :type Image format. Possible values are (case insensitive): JPG, JPEG, PNG. If not specified, the type is inferred from the file extension.
  # @param mixed :link URL or identifier returned by AddLink().
  # @since 1.1
  # @see AddLink()
  #
  def Image(file, x, y, w=0, h=0, type='', link=nil)
    #Put an image on the page
    if (@images[file].nil?)
      #First use of image, get info
      if (type == '')
        pos = file.rindex('.');
        if (pos == 0)
          Error('Image file has no extension and no type was specified: ' + file);
        end
        type = file[pos+1..-1];
      end
      type.downcase!
      if (type == 'jpg' or type == 'jpeg')
        info=parsejpg(file);
      elsif (type == 'png')
        info=parsepng(file);
      else
        #Allow for additional formats
        mtd='parse' + type;
        if (!self.respond_to?(mtd))
          Error('Unsupported image type: ' + type);
        end
        info=send(mtd, file);
      end
      info['i']=@images.length+1;
      @images[file] = info;
    else
      info=@images[file];
    end
    #Automatic width and height calculation if needed
    if ((w == 0) and (h == 0))
      #Put image at 72 dpi
      # 2004-06-14 :: Nicola Asuni, scale factor where added
      w = info['w'] / (@img_scale * @k);
      h = info['h'] / (@img_scale * @k);
    end
    if (w == 0)
      w = h * info['w'] / info['h'];
    end
    if (h == 0)
      h = w * info['h'] / info['w'];
    end
    out(sprintf('q %.2f 0 0 %.2f %.2f %.2f cm /I%d Do Q', w*@k, h*@k, x*@k, (@h-(y+h))*@k, info['i']));
    if (link)
      Link(x, y, w, h, link);
    end

    #2002-07-31 - Nicola Asuni
    # set right-bottom corner coordinates
    @img_rb_x = x + w;
    @img_rb_y = y + h;
  end
  alias_method :image, :Image

  #
  # Performs a line break. The current abscissa goes back to the left margin and the ordinate increases by the amount passed in parameter.
  # @param float :h The height of the break. By default, the value equals the height of the last printed cell.
  # @since 1.0
  # @see Cell()
  #
  def Ln(h='')
    #Line feed; default value is last cell height
    @x=@l_margin;
    if (h.is_a?(String))
      @y += @lasth;
    else
      @y += h;
    end
  end
  alias_method :ln, :Ln

  #
  # Returns the abscissa of the current position.
  # @return float
  # @since 1.2
  # @see SetX(), GetY(), SetY()
  #
  def GetX()
    #Get x position
    return @x;
  end
  alias_method :get_x, :GetX

  #
  # Defines the abscissa of the current position. If the passed value is negative, it is relative to the right of the page.
  # @param float :x The value of the abscissa.
  # @since 1.2
  # @see GetX(), GetY(), SetY(), SetXY()
  #
  def SetX(x)
    #Set x position
    if (x>=0)
      @x = x;
    else
      @x=@w+x;
    end
  end
  alias_method :set_x, :SetX

  #
  # Returns the ordinate of the current position.
  # @return float
  # @since 1.0
  # @see SetY(), GetX(), SetX()
  #
  def GetY()
    #Get y position
    return @y;
  end
  alias_method :get_y, :GetY

  #
  # Moves the current abscissa back to the left margin and sets the ordinate. If the passed value is negative, it is relative to the bottom of the page.
  # @param float :y The value of the ordinate.
  # @since 1.0
  # @see GetX(), GetY(), SetY(), SetXY()
  #
  def SetY(y)
    #Set y position and reset x
    @x=@l_margin;
    if (y>=0)
      @y = y;
    else
      @y=@h+y;
    end
  end
  alias_method :set_y, :SetY

  #
  # Defines the abscissa and ordinate of the current position. If the passed values are negative, they are relative respectively to the right and bottom of the page.
  # @param float :x The value of the abscissa
  # @param float :y The value of the ordinate
  # @since 1.2
  # @see SetX(), SetY()
  #
  def SetXY(x, y)
    #Set x and y positions
    SetY(y);
    SetX(x);
  end
  alias_method :set_xy, :SetXY

  #
  # Send the document to a given destination: string, local file or browser. In the last case, the plug-in may be used (if present) or a download ("Save as" dialog box) may be forced.<br />
  # The method first calls Close() if necessary to terminate the document.
  # @param string :name The name of the file. If not given, the document will be sent to the browser (destination I) with the name doc.pdf.
  # @param string :dest Destination where to send the document. It can take one of the following values:<ul><li>I: send the file inline to the browser. The plug-in is used if available. The name given by name is used when one selects the "Save as" option on the link generating the PDF.</li><li>D: send to the browser and force a file download with the name given by name.</li><li>F: save to a local file with the name given by name.</li><li>S: return the document as a string. name is ignored.</li></ul>If the parameter is not specified but a name is given, destination is F. If no parameter is specified at all, destination is I.<br />
  # @since 1.0
  # @see Close()
  #
  def Output(name='', dest='')
    #Output PDF to some destination
    #Finish document if necessary
    if (@state < 3)
      Close();
    end
    #Normalize parameters
    # Boolean no longer supported
    # if (dest.is_a?(Boolean))
    #   dest = dest ? 'D' : 'F';
    # end
    dest = dest.upcase
    if (dest=='')
      if (name=='')
        name='doc.pdf';
        dest='I';
      else
        dest='F';
      end
    end
    case (dest)
      when 'I'
        # This is PHP specific code
        ##Send to standard output
        # if (ob_get_contents())
        #   Error('Some data has already been output, can\'t send PDF file');
        # end
        # if (php_sapi_name()!='cli')
        #   #We send to a browser
        #   header('Content-Type: application/pdf');
        #   if (headers_sent())
        #     Error('Some data has already been output to browser, can\'t send PDF file');
        #   end
        #   header('Content-Length: ' + @buffer.length);
        #   header('Content-disposition: inline; filename="' + name + '"');
        # end
        return @buffer;

      when 'D'
        # PHP specific
        #Download file
        # if (ob_get_contents())
        #   Error('Some data has already been output, can\'t send PDF file');
        # end
        # if (!_SERVER['HTTP_USER_AGENT'].nil? && SERVER['HTTP_USER_AGENT'].include?('MSIE'))
        #   header('Content-Type: application/force-download');
        # else
        #   header('Content-Type: application/octet-stream');
        # end
        # if (headers_sent())
        #   Error('Some data has already been output to browser, can\'t send PDF file');
        # end
        # header('Content-Length: '+ @buffer.length);
        # header('Content-disposition: attachment; filename="' + name + '"');
        return @buffer;

      when 'F'
        open(name,'wb') do |f|
          f.write(@buffer)
        end
         # PHP code
         #         #Save to local file
         #         f=open(name,'wb');
         #         if (!f)
         #           Error('Unable to create output file: ' + name);
         #         end
         #         fwrite(f,@buffer,@buffer.length);
         #         f.close

      when 'S'
        #Return as a string
        return @buffer;
      else
        Error('Incorrect output destination: ' + dest);

    end
    return '';
  end
  alias_method :output, :Output

  # Protected methods

  #
  # Check for locale-related bug
  # @access protected
  #
  def dochecks()
    #Check for locale-related bug
    if (1.1==1)
      Error('Don\'t alter the locale before including class file');
    end
    #Check for decimal separator
    if (sprintf('%.1f',1.0)!='1.0')
      setlocale(LC_NUMERIC,'C');
    end
  end

  #
  # Return fonts path
  # @access protected
  #
  def getfontpath(file)
    # Is it in the @@font_path?
    if @@font_path
      fpath = File.join @@font_path, file
      if File.exists?(fpath)
        return fpath
      end
    end
    # Is it in this plugin's font folder?
    fpath = File.join File.dirname(__FILE__), 'fonts', file
    if File.exists?(fpath)
      return fpath
    end
    # Could not find it.
    nil
  end

  #
  # Start document
  # @access protected
  #
  def begindoc()
    #Start document
    @state=1;
    out('%PDF-1.3');
  end

  #
  # putpages
  # @access protected
  #
  def putpages()
    nb = @page;
    if (@alias_nb_pages)
      nbstr = UTF8ToUTF16BE(nb, false);
      #Replace number of pages
      1.upto(nb) do |n|
        @pages[n].gsub!(@alias_nb_pages, nbstr)
      end
    end
    if @def_orientation=='P'
      w_pt=@fw_pt
      h_pt=@fh_pt
    else
      w_pt=@fh_pt
      h_pt=@fw_pt
    end
    filter=(@compress) ? '/Filter /FlateDecode ' : ''
    1.upto(nb) do |n|
      #Page
      newobj
      out('<</Type /Page')
      out('/Parent 1 0 R')
      unless @orientation_changes[n].nil?
        out(sprintf('/MediaBox [0 0 %.2f %.2f]', h_pt, w_pt))
      end
      out('/Resources 2 0 R')
      if @page_links[n]
        #Links
        annots='/Annots ['
        @page_links[n].each do |pl|
          rect=sprintf('%.2f %.2f %.2f %.2f', pl[0], pl[1], pl[0]+pl[2], pl[1]-pl[3]);
          annots<<'<</Type /Annot /Subtype /Link /Rect [' + rect + '] /Border [0 0 0] ';
          if (pl[4].is_a?(String))
            annots<<'/A <</S /URI /URI (' + escape(pl[4]) + ')>>>>';
          else
            l=@links[pl[4]];
            h=!@orientation_changes[l[0]].nil? ? w_pt : h_pt;
            annots<<sprintf('/Dest [%d 0 R /XYZ 0 %.2f null]>>',1+2*l[0], h-l[1]*@k);
          end
        end
        out(annots + ']');
      end
      out('/Contents ' + (@n+1).to_s + ' 0 R>>');
      out('endobj');
      #Page content
      p=(@compress) ? gzcompress(@pages[n]) : @pages[n];
      newobj();
      out('<<' + filter + '/Length '+ p.length.to_s + '>>');
      putstream(p);
      out('endobj');
    end
    #Pages root
    @offsets[1]=@buffer.length;
    out('1 0 obj');
    out('<</Type /Pages');
    kids='/Kids [';
    0.upto(nb) do |i|
      kids<<(3+2*i).to_s + ' 0 R ';
    end
    out(kids + ']');
    out('/Count ' + nb.to_s);
    out(sprintf('/MediaBox [0 0 %.2f %.2f]', w_pt, h_pt));
    out('>>');
    out('endobj');
  end

  #
  # Adds fonts
  # putfonts
  # @access protected
  #
  def putfonts()
    nf=@n;
    @diffs.each do |diff|
      #Encodings
      newobj();
      out('<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences [' + diff + ']>>');
      out('endobj');
    end
    @font_files.each do |file, info|
      #Font file embedding
      newobj();
      @font_files[file]['n']=@n;
      font='';
      open(getfontpath(file),'rb') do |f|
        font = f.read();
      end
      compressed=(file[-2,2]=='.z');
      if (!compressed && !info['length2'].nil?)
        header=((font[0][0])==128);
        if (header)
          #Strip first binary header
          font=font[6];
        end
        if header && (font[info['length1']][0] == 128)
          #Strip second binary header
          font=font[0..info['length1']] + font[info['length1']+6];
        end
      end
      out('<</Length '+ font.length.to_s);
      if (compressed)
        out('/Filter /FlateDecode');
      end
      out('/Length1 ' + info['length1'].to_s);
      if (!info['length2'].nil?)
        out('/Length2 ' + info['length2'].to_s + ' /Length3 0');
      end
      out('>>');
      open(getfontpath(file),'rb') do |f|
        putstream(font)
      end
      out('endobj');
    end
    @fonts.each do |k, font|
      #Font objects
      @fonts[k]['n']=@n+1;
      type = font['type'];
      name = font['name'];
      if (type=='core')
        #Standard font
        newobj();
        out('<</Type /Font');
        out('/BaseFont /' + name);
        out('/Subtype /Type1');
        if (name!='Symbol' && name!='ZapfDingbats')
          out('/Encoding /WinAnsiEncoding');
        end
        out('>>');
        out('endobj');
      elsif type == 'Type0'
        putType0(font)
      elsif (type=='Type1' || type=='TrueType')
        #Additional Type1 or TrueType font
        newobj();
        out('<</Type /Font');
        out('/BaseFont /' + name);
        out('/Subtype /' + type);
        out('/FirstChar 32 /LastChar 255');
        out('/Widths ' + (@n+1).to_s + ' 0 R');
        out('/FontDescriptor ' + (@n+2).to_s + ' 0 R');
        if (font['enc'])
          if (!font['diff'].nil?)
            out('/Encoding ' + (nf+font['diff']).to_s + ' 0 R');
          else
            out('/Encoding /WinAnsiEncoding');
          end
        end
        out('>>');
        out('endobj');
        #Widths
        newobj();
        cw=font['cw']; # &
        s='[';
        32.upto(255) do |i|
          s << cw[i.chr] + ' ';
        end
        out(s + ']');
        out('endobj');
        #Descriptor
        newobj();
        s='<</Type /FontDescriptor /FontName /' + name;
        font['desc'].each do |k, v|
          s<<' /' + k + ' ' + v;
        end
        file = font['file'];
        if (file)
          s<<' /FontFile' + (type=='Type1' ? '' : '2') + ' ' + @font_files[file]['n'] + ' 0 R';
        end
        out(s + '>>');
        out('endobj');
      else
        #Allow for additional types
        mtd='put' + type.downcase;
        if (!self.respond_to?(mtd))
          Error('Unsupported font type: ' + type)
        else
          self.send(mtd,font)
        end
      end
    end
  end

  def putType0(font)
    #Type0
    out('<</Type /Font')
    out('/Subtype /Type0')
    out('/BaseFont /'+font['name']+'-'+font['cMap'])
    out('/Encoding /'+font['cMap'])
    out('/DescendantFonts ['+(@n+1).to_s+' 0 R]')
    out('>>')
    out('endobj')
    #CIDFont
    newobj()
    out('<</Type /Font')
    out('/Subtype /CIDFontType0')
    out('/BaseFont /'+font['name'])
    out('/CIDSystemInfo <</Registry (Adobe) /Ordering ('+font['registry']['ordering']+') /Supplement '+font['registry']['supplement'].to_s+'>>')
    out('/FontDescriptor '+(@n+1).to_s+' 0 R')
    w='/W [1 ['
    font['cw'].keys.sort.each {|key|
      w+=font['cw'][key].to_s + " "
# ActionController::Base::logger.debug key.to_s
# ActionController::Base::logger.debug font['cw'][key].to_s
    }
    out(w+'] 231 325 500 631 [500] 326 389 500]')
    out('>>')
    out('endobj')
    #Font descriptor
    newobj()
    out('<</Type /FontDescriptor')
    out('/FontName /'+font['name'])
    out('/Flags 6')
    out('/FontBBox [0 -200 1000 900]')
    out('/ItalicAngle 0')
    out('/Ascent 800')
    out('/Descent -200')
    out('/CapHeight 800')
    out('/StemV 60')
    out('>>')
    out('endobj')
  end

  #
  # putimages
  # @access protected
  #
  def putimages()
    filter=(@compress) ? '/Filter /FlateDecode ' : '';
    @images.each do |file, info| # was while(list(file, info)=each(@images))
      newobj();
      @images[file]['n']=@n;
      out('<</Type /XObject');
      out('/Subtype /Image');
      out('/Width ' + info['w'].to_s);
      out('/Height ' + info['h'].to_s);
      if (info['cs']=='Indexed')
        out('/ColorSpace [/Indexed /DeviceRGB ' + (info['pal'].length/3-1) + ' ' + (@n+1) + ' 0 R]');
      else
        out('/ColorSpace /' + info['cs']);
        if (info['cs']=='DeviceCMYK')
          out('/Decode [1 0 1 0 1 0 1 0]');
        end
      end
      out('/BitsPerComponent ' + info['bpc'].to_s);
      if (!info['f'].nil?)
        out('/Filter /' + info['f']);
      end
      if (!info['parms'].nil?)
        out(info['parms']);
      end
      if (!info['trns'].nil? and info['trns'].kind_of?(Array))
        trns='';
        0.upto(info['trns'].length) do |i|
          trns << info['trns'][i] + ' ' + info['trns'][i] + ' ';
        end
        out('/Mask [' + trns + ']');
      end
      out('/Length ' + info['data'].length.to_s + '>>');
      putstream(info['data']);
      @images[file]['data']=nil
      out('endobj');
      #Palette
      if (info['cs']=='Indexed')
        newobj();
        pal=(@compress) ? gzcompress(info['pal']) : :info['pal'];
        out('<<' + filter + '/Length ' + pal.length.to_s + '>>');
        putstream(pal);
        out('endobj');
      end
    end
  end

  #
  # putxobjectdict
  # @access protected
  #
  def putxobjectdict()
    @images.each_value do |image|
      out('/I' + image['i'].to_s + ' ' + image['n'].to_s + ' 0 R');
    end
  end

  #
  # putresourcedict
  # @access protected
  #
  def putresourcedict()
    out('/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]');
    out('/Font <<');
    @fonts.each_value do |font|
      out('/F' + font['i'].to_s + ' ' + font['n'].to_s + ' 0 R');
    end
    out('>>');
    out('/XObject <<');
    putxobjectdict();
    out('>>');
  end

  #
  # putresources
  # @access protected
  #
  def putresources()
    putfonts();
    putimages();
    #Resource dictionary
    @offsets[2]=@buffer.length;
    out('2 0 obj');
    out('<<');
    putresourcedict();
    out('>>');
    out('endobj');
  end

  #
  # putinfo
  # @access protected
  #
  def putinfo()
    out('/Producer ' + textstring(PDF_PRODUCER));
    if (!@title.nil?)
      out('/Title ' + textstring(@title));
    end
    if (!@subject.nil?)
      out('/Subject ' + textstring(@subject));
    end
    if (!@author.nil?)
      out('/Author ' + textstring(@author));
    end
    if (!@keywords.nil?)
      out('/Keywords ' + textstring(@keywords));
    end
    if (!@creator.nil?)
      out('/Creator ' + textstring(@creator));
    end
    out('/CreationDate ' + textstring('D:' + Time.now.strftime('%Y%m%d%H%M%S')));
  end

  #
  # putcatalog
  # @access protected
  #
  def putcatalog()
    out('/Type /Catalog');
    out('/Pages 1 0 R');
    if (@zoom_mode=='fullpage')
      out('/OpenAction [3 0 R /Fit]');
    elsif (@zoom_mode=='fullwidth')
      out('/OpenAction [3 0 R /FitH null]');
    elsif (@zoom_mode=='real')
      out('/OpenAction [3 0 R /XYZ null null 1]');
    elsif (!@zoom_mode.is_a?(String))
      out('/OpenAction [3 0 R /XYZ null null ' + (@zoom_mode/100) + ']');
    end
    if (@layout_mode=='single')
      out('/PageLayout /SinglePage');
    elsif (@layout_mode=='continuous')
      out('/PageLayout /OneColumn');
    elsif (@layout_mode=='two')
      out('/PageLayout /TwoColumnLeft');
    end
  end

  #
  # puttrailer
  # @access protected
  #
  def puttrailer()
    out('/Size ' + (@n+1).to_s);
    out('/Root ' + @n.to_s + ' 0 R');
    out('/Info ' + (@n-1).to_s + ' 0 R');
  end

  #
  # putheader
  # @access protected
  #
  def putheader()
    out('%PDF-' + @pdf_version);
  end

  #
  # enddoc
  # @access protected
  #
  def enddoc()
    putheader();
    putpages();
    putresources();
    #Info
    newobj();
    out('<<');
    putinfo();
    out('>>');
    out('endobj');
    #Catalog
    newobj();
    out('<<');
    putcatalog();
    out('>>');
    out('endobj');
    #Cross-ref
    o=@buffer.length;
    out('xref');
    out('0 ' + (@n+1).to_s);
    out('0000000000 65535 f ');
    1.upto(@n) do |i|
      out(sprintf('%010d 00000 n ',@offsets[i]));
    end
    #Trailer
    out('trailer');
    out('<<');
    puttrailer();
    out('>>');
    out('startxref');
    out(o);
    out('%%EOF');
    @state=3;
  end

  #
  # beginpage
  # @access protected
  #
  def beginpage(orientation)
    @page += 1;
    @pages[@page]='';
    @state=2;
    @x=@l_margin;
    @y=@t_margin;
    @font_family='';
    #Page orientation
    if (orientation.empty?)
      orientation=@def_orientation;
    else
      orientation.upcase!
      if (orientation!=@def_orientation)
        @orientation_changes[@page]=true;
      end
    end
    if (orientation!=@cur_orientation)
      #Change orientation
      if (orientation=='P')
        @w_pt=@fw_pt;
        @h_pt=@fh_pt;
        @w=@fw;
        @h=@fh;
      else
        @w_pt=@fh_pt;
        @h_pt=@fw_pt;
        @w=@fh;
        @h=@fw;
      end
      @page_break_trigger=@h-@b_margin;
      @cur_orientation = orientation;
    end
  end

  #
  # End of page contents
  # @access protected
  #
  def endpage()
    @state=1;
  end

  #
  # Begin a new object
  # @access protected
  #
  def newobj()
    @n += 1;
    @offsets[@n]=@buffer.length;
    out(@n.to_s + ' 0 obj');
  end

  #
  # Underline text
  # @access protected
  #
  def dounderline(x, y, txt)
    up = @current_font['up'];
    ut = @current_font['ut'];
    w = GetStringWidth(txt) + @ws * txt.count(' ');
    sprintf('%.2f %.2f %.2f %.2f re f', x * @k, (@h - (y - up / 1000.0 * @font_size)) * @k, w * @k, -ut / 1000.0 * @font_size_pt);
  end

  #
  # Extract info from a JPEG file
  # @access protected
  #
  def parsejpg(file)
    a=getimagesize(file);
    if (a.empty?)
      Error('Missing or incorrect image file: ' + file);
    end
    if (a[2]!='JPEG')
      Error('Not a JPEG file: ' + file);
    end
    if (a['channels'].nil? or a['channels']==3)
      colspace='DeviceRGB';
    elsif (a['channels']==4)
      colspace='DeviceCMYK';
    else
      colspace='DeviceGray';
    end
    bpc=!a['bits'].nil? ? a['bits'] : 8;
    #Read whole file
    data='';
    open(file,'rb') do |f|
      data<<f.read();
    end
    return {'w' => a[0],'h' => a[1],'cs' => colspace,'bpc' => bpc,'f'=>'DCTDecode','data' => data}
  end

  #
  # Extract info from a PNG file
  # @access protected
  #
  def parsepng(file)
    f=open(file,'rb');
    #Check signature
    if (f.read(8)!=137.chr + 'PNG' + 13.chr + 10.chr + 26.chr + 10.chr)
      Error('Not a PNG file: ' + file);
    end
    #Read header chunk
    f.read(4);
    if (f.read(4)!='IHDR')
      Error('Incorrect PNG file: ' + file);
    end
    w=freadint(f);
    h=freadint(f);
    bpc=f.read(1)[0];
    if (bpc>8)
      Error('16-bit depth not supported: ' + file);
    end
    ct=f.read(1)[0];
    if (ct==0)
      colspace='DeviceGray';
    elsif (ct==2)
      colspace='DeviceRGB';
    elsif (ct==3)
      colspace='Indexed';
    else
      Error('Alpha channel not supported: ' + file);
    end
    if (f.read(1)[0] != 0)
      Error('Unknown compression method: ' + file);
    end
    if (f.read(1)[0]!=0)
      Error('Unknown filter method: ' + file);
    end
    if (f.read(1)[0]!=0)
      Error('Interlacing not supported: ' + file);
    end
    f.read(4);
    parms='/DecodeParms <</Predictor 15 /Colors ' + (ct==2 ? 3 : 1).to_s + ' /BitsPerComponent ' + bpc.to_s + ' /Columns ' + w.to_s + '>>';
    #Scan chunks looking for palette, transparency and image data
    pal='';
    trns='';
    data='';
    begin
      n=freadint(f);
      type=f.read(4);
      if (type=='PLTE')
        #Read palette
        pal=f.read( n);
        f.read(4);
      elsif (type=='tRNS')
        #Read transparency info
        t=f.read( n);
        if (ct==0)
          trns = t[1][0]
        elsif (ct==2)
          trns = t[[1][0], t[3][0], t[5][0]]
        else
          pos=t.include?(0.chr);
          if (pos!=false)
            trns = [pos]
          end
        end
        f.read(4);
      elsif (type=='IDAT')
        #Read image data block
        data<<f.read( n);
        f.read(4);
      elsif (type=='IEND')
        break;
      else
        f.read( n+4);
      end
    end while(n)
    if (colspace=='Indexed' and pal.empty?)
      Error('Missing palette in ' + file);
    end
    f.close
    return {'w' => w, 'h' => h, 'cs' => colspace, 'bpc' => bpc, 'f'=>'FlateDecode', 'parms' => parms, 'pal' => pal, 'trns' => trns, 'data' => data}
  end

  #
  # Read a 4-byte integer from file
  # @access protected
  #
  def freadint(f)
    # Read a 4-byte integer from file
    a = f.read(4).unpack('N')
    return a[0]
  end

  #
  # Format a text string
  # @access protected
  #
  def textstring(s)
    if (@is_unicode)
      #Convert string to UTF-16BE
      s = UTF8ToUTF16BE(s, true);
    end
    return '(' +  escape(s) + ')';
  end

  #
  # Format a text string
  # @access protected
  #
  def escapetext(s)
    if (@is_unicode)
      #Convert string to UTF-16BE
      s = UTF8ToUTF16BE(s, false);
    end
    return escape(s);
  end

  #
  # Add \ before \, ( and )
  # @access protected
  #
  def escape(s)
    # Add \ before \, ( and )
    s.gsub('\\','\\\\\\').gsub('(','\\(').gsub(')','\\)').gsub(13.chr, '\r')
  end

  #
  #
  # @access protected
  #
  def putstream(s)
    out('stream');
    out(s);
    out('endstream');
  end

  #
  # Add a line to the document
  # @access protected
  #
  def out(s)
    if (@state==2)
      @pages[@page] << s.to_s + "\n";
    else
      @buffer << s.to_s + "\n";
    end
  end

  #
  # Adds unicode fonts.<br>
  # Based on PDF Reference 1.3 (section 5)
  # @access protected
  # @author Nicola Asuni
  # @since 1.52.0.TC005 (2005-01-05)
  #
  def puttruetypeunicode(font)
    # Type0 Font
    # A composite font composed of other fonts, organized hierarchically
    newobj();
    out('<</Type /Font');
    out('/Subtype /Type0');
    out('/BaseFont /' + font['name'] + '');
    out('/Encoding /Identity-H'); #The horizontal identity mapping for 2-byte CIDs; may be used with CIDFonts using any Registry, Ordering, and Supplement values.
    out('/DescendantFonts [' + (@n + 1).to_s + ' 0 R]');
    out('/ToUnicode ' + (@n + 2).to_s + ' 0 R');
    out('>>');
    out('endobj');

    # CIDFontType2
    # A CIDFont whose glyph descriptions are based on TrueType font technology
    newobj();
    out('<</Type /Font');
    out('/Subtype /CIDFontType2');
    out('/BaseFont /' + font['name'] + '');
    out('/CIDSystemInfo ' + (@n + 2).to_s + ' 0 R');
    out('/FontDescriptor ' + (@n + 3).to_s + ' 0 R');
    if (!font['desc']['MissingWidth'].nil?)
      out('/DW ' + font['desc']['MissingWidth'].to_s + ''); # The default width for glyphs in the CIDFont MissingWidth
    end
    w = "";
    font['cw'].each do |cid, width|
      w << '' + cid.to_s + ' [' + width.to_s + '] '; # define a specific width for each individual CID
    end
    out('/W [' + w + ']'); # A description of the widths for the glyphs in the CIDFont
    out('/CIDToGIDMap ' + (@n + 4).to_s + ' 0 R');
    out('>>');
    out('endobj');

    # ToUnicode
    # is a stream object that contains the definition of the CMap
    # (PDF Reference 1.3 chap. 5.9)
    newobj();
    out('<</Length 383>>');
    out('stream');
    out('/CIDInit /ProcSet findresource begin');
    out('12 dict begin');
    out('begincmap');
    out('/CIDSystemInfo');
    out('<</Registry (Adobe)');
    out('/Ordering (UCS)');
    out('/Supplement 0');
    out('>> def');
    out('/CMapName /Adobe-Identity-UCS def');
    out('/CMapType 2 def');
    out('1 begincodespacerange');
    out('<0000> <FFFF>');
    out('endcodespacerange');
    out('1 beginbfrange');
    out('<0000> <FFFF> <0000>');
    out('endbfrange');
    out('endcmap');
    out('CMapName currentdict /CMap defineresource pop');
    out('end');
    out('end');
    out('endstream');
    out('endobj');

    # CIDSystemInfo dictionary
    # A dictionary containing entries that define the character collection of the CIDFont.
    newobj();
    out('<</Registry (Adobe)'); # A string identifying an issuer of character collections
    out('/Ordering (UCS)'); # A string that uniquely names a character collection issued by a specific registry
    out('/Supplement 0'); # The supplement number of the character collection.
    out('>>');
    out('endobj');

    # Font descriptor
    # A font descriptor describing the CIDFont default metrics other than its glyph widths
    newobj();
    out('<</Type /FontDescriptor');
    out('/FontName /' + font['name']);
    font['desc'].each do |key, value|
      out('/' + key.to_s + ' ' + value.to_s);
    end
    if (font['file'])
      # A stream containing a TrueType font program
      out('/FontFile2 ' + @font_files[font['file']]['n'].to_s + ' 0 R');
    end
    out('>>');
    out('endobj');

    # Embed CIDToGIDMap
    # A specification of the mapping from CIDs to glyph indices
    newobj();
    ctgfile = getfontpath(font['ctg'])
    if (!ctgfile)
      Error('Font file not found: ' + ctgfile);
    end
    size = File.size(ctgfile);
    out('<</Length ' + size.to_s + '');
    if (ctgfile[-2,2] == '.z') # check file extension
      # Decompresses data encoded using the public-domain
      # zlib/deflate compression method, reproducing the
      # original text or binary data#
      out('/Filter /FlateDecode');
    end
    out('>>');
    open(ctgfile, "rb") do |f|
      putstream(f.read())
    end
    out('endobj');
  end

   #
  # Converts UTF-8 strings to codepoints array.<br>
  # Invalid byte sequences will be replaced with 0xFFFD (replacement character)<br>
  # Based on: http://www.faqs.org/rfcs/rfc3629.html
  # <pre>
  #     Char. number range  |        UTF-8 octet sequence
  #       (hexadecimal)    |              (binary)
  #    --------------------+-----------------------------------------------
  #    0000 0000-0000 007F | 0xxxxxxx
  #    0000 0080-0000 07FF | 110xxxxx 10xxxxxx
  #    0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
  #    0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
  #    ---------------------------------------------------------------------
  #
  #   ABFN notation:
  #   ---------------------------------------------------------------------
  #   UTF8-octets =#( UTF8-char )
  #   UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
  #   UTF8-1      = %x00-7F
  #   UTF8-2      = %xC2-DF UTF8-tail
  #
  #   UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
  #                 %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
  #   UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
  #                 %xF4 %x80-8F 2( UTF8-tail )
  #   UTF8-tail   = %x80-BF
  #   ---------------------------------------------------------------------
  # </pre>
  # @param string :str string to process.
  # @return array containing codepoints (UTF-8 characters values)
  # @access protected
  # @author Nicola Asuni
  # @since 1.53.0.TC005 (2005-01-05)
  #
  def UTF8StringToArray(str)
    if (!@is_unicode)
      return str; # string is not in unicode
    end

    unicode = [] # array containing unicode values
    bytes  = [] # array containing single character byte sequences
    numbytes  = 1; # number of octetc needed to represent the UTF-8 character

    str = str.to_s; # force :str to be a string

    str.each_byte do |char|
      if (bytes.length == 0) # get starting octect
        if (char <= 0x7F)
          unicode << char # use the character "as is" because is ASCII
          numbytes = 1
        elsif ((char >> 0x05) == 0x06) # 2 bytes character (0x06 = 110 BIN)
          bytes << ((char - 0xC0) << 0x06)
          numbytes = 2
        elsif ((char >> 0x04) == 0x0E) # 3 bytes character (0x0E = 1110 BIN)
          bytes << ((char - 0xE0) << 0x0C)
          numbytes = 3
        elsif ((char >> 0x03) == 0x1E) # 4 bytes character (0x1E = 11110 BIN)
          bytes << ((char - 0xF0) << 0x12)
          numbytes = 4
        else
          # use replacement character for other invalid sequences
          unicode << 0xFFFD
          bytes = []
          numbytes = 1
        end
      elsif ((char >> 0x06) == 0x02) # bytes 2, 3 and 4 must start with 0x02 = 10 BIN
        bytes << (char - 0x80)
        if (bytes.length == numbytes)
          # compose UTF-8 bytes to a single unicode value
          char = bytes[0]
          1.upto(numbytes-1) do |j|
            char += (bytes[j] << ((numbytes - j - 1) * 0x06))
          end
          if (((char >= 0xD800) and (char <= 0xDFFF)) or (char >= 0x10FFFF))
            # The definition of UTF-8 prohibits encoding character numbers between
            # U+D800 and U+DFFF, which are reserved for use with the UTF-16
            # encoding form (as surrogate pairs) and do not directly represent
            # characters
            unicode << 0xFFFD; # use replacement character
          else
            unicode << char; # add char to array
          end
          # reset data for next char
          bytes = []
          numbytes = 1;
        end
      else
        # use replacement character for other invalid sequences
        unicode << 0xFFFD;
        bytes = []
        numbytes = 1;
      end
    end
    return unicode;
  end

  #
  # Converts UTF-8 strings to UTF16-BE.<br>
  # Based on: http://www.faqs.org/rfcs/rfc2781.html
   # <pre>
  #   Encoding UTF-16:
  #
    #   Encoding of a single character from an ISO 10646 character value to
  #    UTF-16 proceeds as follows. Let U be the character number, no greater
  #    than 0x10FFFF.
  #
  #    1) If U < 0x10000, encode U as a 16-bit unsigned integer and
  #       terminate.
  #
  #    2) Let U' = U - 0x10000. Because U is less than or equal to 0x10FFFF,
  #       U' must be less than or equal to 0xFFFFF. That is, U' can be
  #       represented in 20 bits.
  #
  #    3) Initialize two 16-bit unsigned integers, W1 and W2, to 0xD800 and
  #       0xDC00, respectively. These integers each have 10 bits free to
  #       encode the character value, for a total of 20 bits.
  #
  #    4) Assign the 10 high-order bits of the 20-bit U' to the 10 low-order
  #       bits of W1 and the 10 low-order bits of U' to the 10 low-order
  #       bits of W2. Terminate.
  #
  #    Graphically, steps 2 through 4 look like:
  #    U' = yyyyyyyyyyxxxxxxxxxx
  #    W1 = 110110yyyyyyyyyy
  #    W2 = 110111xxxxxxxxxx
  # </pre>
  # @param string :str string to process.
  # @param boolean :setbom if true set the Byte Order Mark (BOM = 0xFEFF)
  # @return string
  # @access protected
  # @author Nicola Asuni
  # @since 1.53.0.TC005 (2005-01-05)
  # @uses UTF8StringToArray
  #
  def UTF8ToUTF16BE(str, setbom=true)
    if (!@is_unicode)
      return str; # string is not in unicode
    end
    outstr = ""; # string to be returned
    unicode = UTF8StringToArray(str); # array containing UTF-8 unicode values
    numitems = unicode.length;

    if (setbom)
      outstr << "\xFE\xFF"; # Byte Order Mark (BOM)
    end
    unicode.each do |char|
      if (char == 0xFFFD)
        outstr << "\xFF\xFD"; # replacement character
      elsif (char < 0x10000)
        outstr << (char >> 0x08).chr;
        outstr << (char & 0xFF).chr;
      else
        char -= 0x10000;
        w1 = 0xD800 | (char >> 0x10);
        w2 = 0xDC00 | (char & 0x3FF);
        outstr << (w1 >> 0x08).chr;
        outstr << (w1 & 0xFF).chr;
        outstr << (w2 >> 0x08).chr;
        outstr << (w2 & 0xFF).chr;
      end
    end
    return outstr;
  end

  # ====================================================

  #
   # Set header font.
  # @param array :font font
  # @since 1.1
  #
  def SetHeaderFont(font)
    @header_font = font;
  end
  alias_method :set_header_font, :SetHeaderFont

  #
   # Set footer font.
  # @param array :font font
  # @since 1.1
  #
  def SetFooterFont(font)
    @footer_font = font;
  end
  alias_method :set_footer_font, :SetFooterFont

  #
   # Set language array.
  # @param array :language
  # @since 1.1
  #
  def SetLanguageArray(language)
    @l = language;
  end
  alias_method :set_language_array, :SetLanguageArray

  #
   # Returns the PDF data.
  #
  def GetPDFData()
    if (@state < 3)
      Close();
    end
    return @buffer;
  end

  # --- HTML PARSER FUNCTIONS ---

  #
  # Allows to preserve some HTML formatting.<br />
  # Supports: h1, h2, h3, h4, h5, h6, b, u, i, a, img, p, br, strong, em, font, blockquote, li, ul, ol, hr, td, th, tr, table, sup, sub, small
  # @param string :html text to display
  # @param boolean :ln if true add a new line after text (default = true)
  # @param int :fill Indicates if the background must be painted (1) or transparent (0). Default value: 0.
  #
  def writeHTML(html, ln=true, fill=0, h=0)

    @lasth = h if h > 0
    if (@lasth == 0)
      #set row height
      @lasth = @font_size * @@k_cell_height_ratio;
    end

    @href = nil
    @style = {}
    html.gsub!(/[\t\r\n\f]/, "")#\0\x0B
    html.split(/(<[^>]+>)/).each do |element|
      if "<" == element[0,1]
        #Tag
        if (element[1, 1] == '/')
          closedHTMLTagHandler(element[2..-2].downcase);
        else
          #Extract attributes
          # get tag name
          tag = element.scan(/([a-zA-Z0-9]*)/).flatten.delete_if {|x| x.length == 0}
          tag = tag[0].downcase;

          # get attributes
          attr_array = element.scan(/([^=\s]*)=["\']?([^"\']*)["\']?/)
          attrs = {}
          attr_array.each do |name, value|
            attrs[name.downcase] = value;
          end
          openHTMLTagHandler(tag, attrs, fill);
        end

      else
        #Text
        if (@href)
          addHtmlLink(@href, element, fill);
        elsif (@tdbegin)
          if ((element.strip.length > 0) and (element != "&nbsp;"))
            Cell(@tdwidth, @tdheight, unhtmlentities(element.strip), @tableborder, 0, @tdalign, @tdfill);
          elsif (element == "&nbsp;")
            Cell(@tdwidth, @tdheight, '', @tableborder, 0, @tdalign, @tdfill);
          end
        elsif ((element.strip.length > 0) and (element != "&nbsp;"))
          Write(@lasth, unhtmlentities(element), '', fill);
        end
      end
    end

    if (ln)
      Ln(@lasth);
    end
  end
  alias_method :write_html, :writeHTML

  #
  # Prints a cell (rectangular area) with optional borders, background color and html text string. The upper-left corner of the cell corresponds to the current position. After the call, the current position moves to the right or to the next line.<br />
  # If automatic page breaking is enabled and the cell goes beyond the limit, a page break is done before outputting.
  # @param float :w Cell width. If 0, the cell extends up to the right margin.
  # @param float :h Cell minimum height. The cell extends automatically if needed.
  # @param float :x upper-left corner X coordinate
  # @param float :y upper-left corner Y coordinate
  # @param string :html html text to print. Default value: empty string.
  # @param mixed :border Indicates if borders must be drawn around the cell. The value can be either a number:<ul><li>0: no border (default)</li><li>1: frame</li></ul>or a string containing some or all of the following characters (in any order):<ul><li>L: left</li><li>T: top</li><li>R: right</li><li>B: bottom</li></ul>
  # @param int :ln Indicates where the current position should go after the call. Possible values are:<ul><li>0: to the right</li><li>1: to the beginning of the next line</li><li>2: below</li></ul>
# Putting 1 is equivalent to putting 0 and calling Ln() just after. Default value: 0.
  # @param int :fill Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # @see Cell()
  #
  def writeHTMLCell(w, h, x, y, html='', border=0, ln=0, fill=0)

    if (@lasth == 0)
      #set row height
      @lasth = @font_size * @@k_cell_height_ratio;
    end

    if (x == 0)
      x = GetX();
    end
    if (y == 0)
      y = GetY();
    end

    # get current page number
    pagenum = @page;

    SetX(x);
    SetY(y);

    if (w == 0)
      w = @fw - x - @r_margin;
    end

    # store original margin values
    l_margin = @l_margin;
    r_margin = @r_margin;

    # set new margin values
    SetLeftMargin(x);
    SetRightMargin(@fw - x - w);

    # calculate remaining vertical space on page
    restspace = GetPageHeight() - GetY() - GetBreakMargin();

    writeHTML(html, true, fill); # write html text

    currentY =  GetY();

    # check if a new page has been created
    if (@page > pagenum)
      # design a cell around the text on first page
      currentpage = @page;
      @page = pagenum;
      SetY(GetPageHeight() - restspace - GetBreakMargin());
      h = restspace - 1;
      Cell(w, h, "", border, ln, 'L', 0);
      # design a cell around the text on last page
      @page = currentpage;
      h = currentY - @t_margin;
      SetY(@t_margin); # put cursor at the beginning of text
      Cell(w, h, "", border, ln, 'L', 0);
    else
      h = [h, (currentY - y)].max;
      SetY(y); # put cursor at the beginning of text
      # design a cell around the text
      Cell(w, h, "", border, ln, 'L', 0);
    end

    # restore original margin values
    SetLeftMargin(l_margin);
    SetRightMargin(r_margin);

    if (ln)
      Ln(0);
    end
  end
  alias_method :write_html_cell, :writeHTMLCell

  #
  # Process opening tags.
  # @param string :tag tag name (in upcase)
  # @param string :attr tag attribute (in upcase)
  # @param int :fill Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # @access private
  #
  def openHTMLTagHandler(tag, attrs, fill=0)
    #Opening tag
    case (tag)
      when 'table'
        if attrs['border'].nil? or attrs['border'] == ''
          @tableborder = 0;
        else
          @tableborder = attrs['border'];
        end
      when 'tr', 'td', 'th'
        # SetStyle('b', true) if tag == 'th'

        if ((!attrs['width'].nil?) and (attrs['width'] != ''))
          @tdwidth = (attrs['width'].to_i/4);
        else
          @tdwidth = ((@w - @l_margin - @r_margin) / @default_table_columns);
        end
        if ((!attrs['height'].nil?) and (attrs['height'] != ''))
          @tdheight=(attrs['height'].to_i / @k);
        else
          @tdheight = @lasth;
        end
        if ((!attrs['align'].nil?) and (attrs['align'] != ''))
          case (attrs['align'])
            when 'center'
              @tdalign = "C";
            when 'right'
              @tdalign = "R";
            when 'left'
              @tdalign = "L";
          end
        end
        if ((!attrs['bgcolor'].nil?) and (attrs['bgcolor'] != ''))
          coul = convertColorHexToDec(attrs['bgcolor']);
          SetFillColor(coul['R'], coul['G'], coul['B']);
          @tdfill=1;
        end
        @tdbegin=true;

      when 'hr'
        Ln();
        if ((!attrs['width'].nil?) and (attrs['width'] != ''))
          hrWidth = attrs['width'];
        else
          hrWidth = @w - @l_margin - @r_margin;
        end
        x = GetX();
        y = GetY();
        SetLineWidth(0.2);
        Line(x, y, x + hrWidth, y);
        SetLineWidth(0.2);
        Ln();

      when 'strong'
        SetStyle('b', true);

      when 'em'
        SetStyle('i', true);

      when 'b', 'i', 'u'
        SetStyle(tag, true);

      when 'a'
        @href = attrs['href'];

      when 'img'
        if (!attrs['src'].nil?)
          # replace relative path with real server path
          attrs['src'] = attrs['src'].gsub(@@k_path_url_cache, @@k_path_cache);
          if (attrs['width'].nil?)
            attrs['width'] = 0;
          end
          if (attrs['height'].nil?)
            attrs['height'] = 0;
          end

          Image(attrs['src'], GetX(),GetY(), pixelsToMillimeters(attrs['width']), pixelsToMillimeters(attrs['height']));
          #SetX(@img_rb_x);
          SetY(@img_rb_y);

        end

      when 'ul'
        @listordered = false;
        @listcount = 0;

      when 'ol'
        @listordered = true;
        @listcount = 0;

      when 'li'
        Ln();
        if (@listordered)
          @listcount += 1
          @lispacer = "    " + (@listcount).to_s + ". ";
        else
          #unordered list simbol
          @lispacer = "    -  ";
        end
        Write(@lasth, @lispacer, '', fill);

      when 'blockquote', 'br'
        Ln();
        if (@lispacer.length > 0)
          @x += GetStringWidth(@lispacer);
        end

      when 'p'
        Ln();
        Ln();

      when 'sup'
        currentfont_size = @font_size;
        @tempfontsize = @font_size_pt;
        SetFontSize(@font_size_pt * @@k_small_ratio);
        SetXY(GetX(), GetY() - ((currentfont_size - @font_size)*(@@k_small_ratio)));

      when 'sub'
        currentfont_size = @font_size;
        @tempfontsize = @font_size_pt;
        SetFontSize(@font_size_pt * @@k_small_ratio);
        SetXY(GetX(), GetY() + ((currentfont_size - @font_size)*(@@k_small_ratio)));

      when 'small'
        currentfont_size = @font_size;
        @tempfontsize = @font_size_pt;
        SetFontSize(@font_size_pt * @@k_small_ratio);
        SetXY(GetX(), GetY() + ((currentfont_size - @font_size)/3));

      when 'font'
        if (!attrs['color'].nil? and attrs['color']!='')
          coul = convertColorHexToDec(attrs['color']);
          SetTextColor(coul['R'], coul['G'], coul['B']);
          @issetcolor=true;
        end
        if (!attrs['face'].nil? and @fontlist.include?(attrs['face'].downcase))
          SetFont(attrs['face'].downcase);
          @issetfont=true;
        end
        if (!attrs['size'].nil?)
          headsize = attrs['size'].to_i;
        else
          headsize = 0;
        end
        currentfont_size = @font_size;
        @tempfontsize = @font_size_pt;
        SetFontSize(@font_size_pt + headsize);
        @lasth = @font_size * @@k_cell_height_ratio;

      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        headsize = (4 - tag[1,1].to_f) * 2
        @tempfontsize = @font_size_pt;
        SetFontSize(@font_size_pt + headsize);
        SetStyle('b', true);
        @lasth = @font_size * @@k_cell_height_ratio;

    end
  end

  #
  # Process closing tags.
  # @param string :tag tag name (in upcase)
  # @access private
  #
  def closedHTMLTagHandler(tag)
    #Closing tag
    case (tag)
      when 'td','th'
        @tdbegin = false;
        @tdwidth = 0;
        @tdheight = 0;
        @tdalign = "L";
        @tdfill = 0;
        SetFillColor(@prevfill_color[0], @prevfill_color[1], @prevfill_color[2]);

      when 'tr'
        Ln();

      when 'table'
        @tableborder=0;

      when 'strong'
        SetStyle('b', false);

      when 'em'
        SetStyle('i', false);

      when 'b', 'i', 'u'
        SetStyle(tag, false);

      when 'a'
        @href = nil;

      when 'sup'
        currentfont_size = @font_size;
        SetFontSize(@tempfontsize);
        @tempfontsize = @font_size_pt;
        SetXY(GetX(), GetY() - ((currentfont_size - @font_size)*(@@k_small_ratio)));

      when 'sub'
        currentfont_size = @font_size;
        SetFontSize(@tempfontsize);
        @tempfontsize = @font_size_pt;
        SetXY(GetX(), GetY() + ((currentfont_size - @font_size)*(@@k_small_ratio)));

      when 'small'
        currentfont_size = @font_size;
        SetFontSize(@tempfontsize);
        @tempfontsize = @font_size_pt;
        SetXY(GetX(), GetY() - ((@font_size - currentfont_size)/3));

      when 'font'
        if (@issetcolor == true)
          SetTextColor(@prevtext_color[0], @prevtext_color[1], @prevtext_color[2]);
        end
        if (@issetfont)
          @font_family = @prevfont_family;
          @font_style = @prevfont_style;
          SetFont(@font_family);
          @issetfont = false;
        end
        currentfont_size = @font_size;
        SetFontSize(@tempfontsize);
        @tempfontsize = @font_size_pt;
        #@text_color = @prevtext_color;
        @lasth = @font_size * @@k_cell_height_ratio;

      when 'ul'
        Ln();

      when 'ol'
        Ln();

      when 'li'
        @lispacer = "";

      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        SetFontSize(@tempfontsize);
        @tempfontsize = @font_size_pt;
        SetStyle('b', false);
        Ln();
        @lasth = @font_size * @@k_cell_height_ratio;

    end
  end

  #
  # Sets font style.
  # @param string :tag tag name (in lowercase)
  # @param boolean :enable
  # @access private
  #
  def SetStyle(tag, enable)
    #Modify style and select corresponding font
    style='';
    ['b', 'i', 'u'].each do |s|
        style << s if tag.downcase == s and enable
    end
    SetFont('', style);
  end

  #
  # Output anchor link.
  # @param string :url link URL
  # @param string :name link name
  # @param int :fill Indicates if the cell background must be painted (1) or transparent (0). Default value: 0.
  # @access public
  #
  def addHtmlLink(url, name, fill=0)
    #Put a hyperlink
    SetTextColor(0, 0, 255);
    SetStyle('u', true);
    Write(@lasth, name, url, fill);
    SetStyle('u', false);
    SetTextColor(0);
  end

  #
  # Returns an associative array (keys: R,G,B) from
  # a hex html code (e.g. #3FE5AA).
  # @param string :color hexadecimal html color [#rrggbb]
  # @return array
  # @access private
  #
  def convertColorHexToDec(color = "#000000")
    tbl_color = {}
    tbl_color['R'] = color[1,2].hex.to_i;
    tbl_color['G'] = color[3,2].hex.to_i;
    tbl_color['B'] = color[5,2].hex.to_i;
    return tbl_color;
  end

  #
  # Converts pixels to millimeters in 72 dpi.
  # @param int :px pixels
  # @return float millimeters
  # @access private
  #
  def pixelsToMillimeters(px)
    return px.to_f * 25.4 / 72;
  end

  #
  # Reverse function for htmlentities.
  # Convert entities in UTF-8.
  #
  # @param :text_to_convert Text to convert.
  # @return string converted
  #
  def unhtmlentities(string)
    if @@decoder.nil?
      CGI.unescapeHTML(string)
    else
      @@decoder.decode(string)
    end
  end

end # END OF CLASS

#TODO 2007-05-25 (EJM) Level=0 -
#Handle special IE contype request
# if (!_SERVER['HTTP_USER_AGENT'].nil? and (_SERVER['HTTP_USER_AGENT']=='contype'))
#   header('Content-Type: application/pdf');
#   exit;
# }

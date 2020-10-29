require 'date'

module Spreadsheet
  module Excel
##
# Binary Formats and other configurations internal to Excel. This Module is
# likely to shrink as Support for older Versions of Excel grows and more Binary
# formats are moved away from here for disambiguation.
# If you need to work with constants defined in this module and are confused by
# names like SEDOC_ROLOC, try reading them backwards. (The reason for this weird
# naming convention is that according to my ri, Ruby 1.9 renames Hash#index to
# Hash#key without backward compatibility. Since I did not want to pepper my code
# with RUBY_VERSION-checks, I settled on this strategy to make the transition to
# Ruby 1.9 as simple as possible.
module Internals
  EIGHT_BYTE_DOUBLE = [0.1].pack('E').size == 8 ? 'E' : 'e'
  CODEPAGES = {
    367 => "ASCII",
    437 => "IBM437", #(US)
    720 => "IBM720", #(OEM Arabic)
    737 => "IBM737", #(Greek)
    775 => "IBM775", #(Baltic)
    850 => "IBM850", #(Latin I)
    852 => "IBM852", #(Latin II (Central European))
    855 => "IBM855", #(Cyrillic)
    857 => "IBM857", #(Turkish)
    858 => "IBM858", #(Multilingual Latin I with Euro)
    860 => "IBM860", #(Portuguese)
    861 => "IBM861", #(Icelandic)
    862 => "IBM862", #(Hebrew)
    863 => "IBM863", #(Canadian (French))
    864 => "IBM864", #(Arabic)
    865 => "IBM865", #(Nordic)
    866 => "IBM866", #(Cyrillic (Russian))
    869 => "IBM869", #(Greek (Modern))
    874 => "WINDOWS-874", #(Thai)
    932 => "Windows-31J", #(Japanese Shift-JIS)
    936 => "GBK", #(Chinese Simplified GBK)
    949 => "CP949", #(Korean (Wansung))
    950 => "CP950", #(Chinese Traditional BIG5)
    1200 => "UTF-16LE", #(BIFF8)
    1250 => "WINDOWS-1250", #(Latin II) (Central European)
    1251 => "WINDOWS-1251", #(Cyrillic)
    1252 => "WINDOWS-1252", #(Latin I) (BIFF4-BIFF7)
    1253 => "WINDOWS-1253", #(Greek)
    1254 => "WINDOWS-1254", #(Turkish)
    1255 => "WINDOWS-1255", #(Hebrew)
    1256 => "WINDOWS-1256", #(Arabic)
    1257 => "WINDOWS-1257", #(Baltic)
    1258 => "WINDOWS-1258", #(Vietnamese)
    1361 => "WINDOWS-1361", #(Korean (Johab))
    10000 => "MACROMAN",
    21010 => "UTF-16LE",
    32768 => "MACROMAN",
    32769 => "WINDOWS-1252", #(Latin I) (BIFF2-BIFF3)
  }
  SEGAPEDOC = CODEPAGES.reject { |k, _v| k >= 21010 }.invert
  # color_codes according to http://support.softartisans.com/kbview_1205.aspx
  # synonyms are in comments when reverse lookup
  COLOR_CODES = {
    0x0000 => :builtin_black,
    0x0001 => :builtin_white,
    0x0002 => :builtin_red,
    0x0003 => :builtin_green,
    0x0004 => :builtin_blue,
    0x0005 => :builtin_yellow,
    0x0006 => :builtin_magenta,
    0x0007 => :builtin_cyan,
    0x0008 => :black,                 #xls_color_0
    0x0009 => :white,                 #xls_color_1
    0x000a => :red,                   #xls_color_2
    0x000b => :lime,                  #xls_color_3
    0x000c => :blue,                  #xls_color_4
    0x000d => :yellow,                #xls_color_5
    0x000e => :magenta,               #xls_color_6, fuchsia
    0x000f => :cyan,                  #xls_color_7, aqua
    0x0010 => :brown,                 #xls_color_8
    0x0011 => :green,                 #xls_color_9
    0x0012 => :navy,                  #xls_color_10
    0x0013 => :xls_color_11,
    0x0014 => :xls_color_12,
    0x0015 => :xls_color_13,
    0x0016 => :silver,                #xls_color_14
    0x0017 => :gray,                  #xls_color_15, grey
    0x0018 => :xls_color_16,
    0x0019 => :xls_color_17,
    0x001a => :xls_color_18,
    0x001b => :xls_color_19,
    0x001c => :xls_color_20,
    0x001d => :xls_color_21,
    0x001e => :xls_color_22,
    0x001f => :xls_color_23,
    0x0020 => :xls_color_24,
    0x0021 => :xls_color_25,
    0x0022 => :xls_color_26,
    0x0023 => :xls_color_27,
    0x0024 => :purple,                #xls_color_28
    0x0025 => :xls_color_29,
    0x0026 => :xls_color_30,
    0x0027 => :xls_color_31,
    0x0028 => :xls_color_32,
    0x0029 => :xls_color_33,
    0x002a => :xls_color_34,
    0x002b => :xls_color_35,
    0x002c => :xls_color_36,
    0x002d => :xls_color_37,
    0x002e => :xls_color_38,
    0x002f => :xls_color_39,
    0x0030 => :xls_color_40,
    0x0031 => :xls_color_41,
    0x0032 => :xls_color_42,
    0x0033 => :xls_color_43,
    0x0034 => :orange,                #xls_color_44
    0x0035 => :xls_color_45,
    0x0036 => :xls_color_46,
    0x0037 => :xls_color_47,
    0x0038 => :xls_color_48,
    0x0039 => :xls_color_49,
    0x003a => :xls_color_50,
    0x003b => :xls_color_51,
    0x003c => :xls_color_52,
    0x003d => :xls_color_53,
    0x003e => :xls_color_54,
    0x003f => :xls_color_55,

    0x0040 => :border,
    0x0041 => :pattern_bg,
    0x0043 => :dialog_bg,
    0x004d => :chart_text,
    0x004e => :chart_bg,
    0x004f => :chart_border,
    0x0050 => :tooltip_bg,
    0x0051 => :tooltip_text,
    0x7fff => :text
  }

  SEDOC_ROLOC = COLOR_CODES.invert.update(
    :xls_color_0  => 0x0008,
    :xls_color_1  => 0x0009,
    :xls_color_2  => 0x000a,
    :xls_color_3  => 0x000b,
    :xls_color_4  => 0x000c,
    :xls_color_5  => 0x000d,
    :xls_color_6  => 0x000e,
    :fuchsia      => 0x000e,
    :xls_color_7  => 0x000f,
    :aqua         => 0x000f,
    :xls_color_8  => 0x0010,
    :xls_color_9  => 0x0011,
    :xls_color_10 => 0x0012,
    :xls_color_14 => 0x0016,
    :xls_color_15 => 0x0017,
    :grey         => 0x0017,
    :xls_color_28 => 0x0024,
    :xls_color_44 => 0x0034
  )

  BINARY_FORMATS = {
    :blank      => 'v3',
    :boolerr    => 'v3C2',
    :colinfo    => 'v5x2',
    :font       => 'v5C3x',
    :labelsst   => 'v3V',
    :number     => "v3#{EIGHT_BYTE_DOUBLE}",
    :pagesetup  => "v8#{EIGHT_BYTE_DOUBLE}2v",
    :margin     => "#{EIGHT_BYTE_DOUBLE}",
    :rk         => 'v3V',
    :row        => 'v4x4V',
    :window2    => 'v4x2v2x4',
    :xf         => 'v3C4V2v',
  }
  # From BIFF5 on, the built-in number formats will be omitted. The built-in
  # formats are dependent on the current regional settings of the operating
  # system. The following table shows which number formats are used by
  # default in a US-English environment. All indexes from 0 to 163 are
  # reserved for built-in formats.
  BUILTIN_FORMATS = { # TODO: locale support
     0 => 'GENERAL',
     1 => '0',
     2 => '0.00',
     3 => '#,##0',
     4 => '#,##0.00',
     5 => '"$"#,##0_);("$"#,##0)',
     6 => '"$"#,##0_);[Red]("$"#,##0)',
     7 => '"$"#,##0.00_);("$"#,##0.00)',
     8 => '"$"#,##0.00_);[Red]("$"#,##0.00)',
     9 => '0%',
    10 => '0.00%',
    11 => '0.00E+00',
    12 => '# ?/?',
    13 => '# ??/??',
    14 => 'M/D/YY',
    15 => 'D-MMM-YY',
    16 => 'D-MMM',
    17 => 'MMM-YY',
    18 => 'h:mm AM/PM',
    19 => 'h:mm:ss AM/PM',
    20 => 'h:mm',
    21 => 'h:mm:ss',
    22 => 'M/D/YY h:mm',
    37 => '_(#,##0_);(#,##0)',
    38 => '_(#,##0_);[Red](#,##0)',
    39 => '_(#,##0.00_);(#,##0.00)',
    40 => '_(#,##0.00_);[Red](#,##0.00)',
    41 => '_("$"* #,##0_);_("$"* (#,##0);_("$"* "-"_);_(@_)',
    42 => '_(* #,##0_);_(* (#,##0);_(* "-"_);_(@_)',
    43 => '_("$"* #,##0.00_);_("$"* (#,##0.00);_("$"* "-"??_);_(@_)',
    44 => '_(* #,##0.00_);_(* (#,##0.00);_(* "-"??_);_(@_)',
    45 => 'mm:ss',
    46 => '[h]:mm:ss',
    47 => 'mm:ss.0',
    48 => '##0.0E+0',
    49 => '@',
  }
  BUILTIN_STYLES = {
    0x00 => 'Normal',
    0x01 => 'RowLevel_lv',
    0x02 => 'ColLevel_lv',
    0x03 => 'Comma',
    0x04 => 'Currency',
    0x05 => 'Percent',
    0x06 => 'Comma',
    0x07 => 'Currency',
    0x08 => 'Hyperlink',
    0x09 => 'Followed Hyperlink',
  }
  ESCAPEMENT_TYPES = {
    0x0001 => :superscript,
    0x0002 => :subscript,
  }
  SEPYT_TNEMEPACSE = ESCAPEMENT_TYPES.invert
  FONT_ENCODINGS = {
    0x00 => :iso_latin1,
    0x01 => :default,
    0x02 => :symbol,
    0x4d => :apple_roman,
    0x80 => :shift_jis,
    0x81 => :korean_hangul,
    0x82 => :korean_johab,
    0x86 => :chinese_simplified,
    0x88 => :chinese_traditional,
    0xa1 => :greek,
    0xa2 => :turkish,
    0xa3 => :vietnamese,
    0xb1 => :hebrew,
    0xb2 => :arabic,
    0xba => :baltic,
    0xcc => :cyrillic,
    0xde => :thai,
    0xee => :iso_latin2,
    0xff => :oem_latin1,
  }
  SGNIDOCNE_TNOF = FONT_ENCODINGS.invert
  FONT_FAMILIES = {
    0x01 => :roman,
    0x02 => :swiss,
    0x03 => :modern,
    0x04 => :script,
    0x05 => :decorative,
  }
  SEILIMAF_TNOF = FONT_FAMILIES.invert
  FONT_WEIGHTS = {
    :bold   => 700,
    :normal => 400,
  }
  WORKSHEET_VISIBILITIES = {
    0x00 => :visible,
    0x01 => :hidden,
    0x02 => :strong_hidden
  }
  SEITILIBISIV_TEEHSKROW = WORKSHEET_VISIBILITIES.invert
  LEAP_ERROR = Date.new 1900, 2, 28
  OPCODES = {
    :blank        => 0x0201, #    BLANK ➜ 6.7
    :boolerr      => 0x0205, #    BOOLERR ➜ 6.10
    :boundsheet   => 0x0085, # ●● BOUNDSHEET ➜ 6.12
    :codepage     => 0x0042, # ○  CODEPAGE ➜ 6.17
    :colinfo      => 0x007d, # ○○ COLINFO ➜ 6.18
    :continue     => 0x003c, # ○  CONTINUE ➜ 6.22
    :datemode     => 0x0022, # ○  DATEMODE ➜ 6.25
    :dbcell       => 0x0a0b, # ○  DBCELL
    :dimensions   => 0x0200, # ●  DIMENSIONS ➜ 6.31
    :eof          => 0x000a, # ●  EOF ➜ 6.36
    :font         => 0x0031, # ●● FONT ➜ 6.43
    :format       => 0x041e, # ○○ FORMAT (Number Format) ➜ 6.45
    :formula      => 0x0006, #    FORMULA ➜ 6.46
    :hlink        => 0x01b8, #    HLINK ➜ 6.52 (BIFF8 only)
    :label        => 0x0204, #    LABEL ➜ 6.59 (BIFF2-BIFF7)
    :labelsst     => 0x00fd, #    LABELSST ➜ 6.61 (BIFF8 only)
    :mergedcells  => 0x00e5, # ○○ MERGEDCELLS	➜ 5.67 (BIFF8 only)
    :mulblank     => 0x00be, #    MULBLANK ➜ 6.64 (BIFF5-BIFF8)
    :mulrk        => 0x00bd, #    MULRK ➜ 6.65 (BIFF5-BIFF8)
    :number       => 0x0203, #    NUMBER ➜ 6.68
    :rk           => 0x027e, #    RK ➜ 6.82 (BIFF3-BIFF8)
    :row          => 0x0208, # ●  ROW ➜ 6.83
    :rstring      => 0x00d6, #    RSTRING ➜ 6.84 (BIFF5/BIFF7)
    :sst          => 0x00fc, # ●  SST ➜ 6.96
    :string       => 0x0207, #    STRING ➜ 6.98
    :style        => 0x0293, # ●● STYLE ➜ 6.99
    :xf           => 0x00e0, # ●● XF ➜ 6.115
    :sharedfmla   => 0x04bc, #    SHAREDFMLA ➜ 5.94
    ########################## Unhandled Opcodes ################################
    :extsst       => 0x00ff, # ●  EXTSST ➜ 6.40
    :index        => 0x020b, # ○  INDEX ➜ 5.7 (Row Blocks), ➜ 6.55
    :uncalced     => 0x005e, # ○  UNCALCED ➜ 6.104
    ########################## ○  Calculation Settings Block ➜ 5.3
    :calccount    => 0x000c, # ○  CALCCOUNT ➜ 6.14
    :calcmode     => 0x000d, # ○  CALCMODE ➜ 6.15
    :precision    => 0x000e, # ○  PRECISION ➜ 6.74 (moved to Workbook Globals
                             #                      Substream in BIFF5-BIFF8)
    :refmode      => 0x000f, # ○  REFMODE ➜ 6.80
    :delta        => 0x0010, # ○  DELTA ➜ 6.30
    :iteration    => 0x0011, # ○  ITERATION ➜ 6.57
    :saverecalc   => 0x005f, # ○  SAVERECALC ➜ 6.85 (BIFF3-BIFF8 only)
    ########################## ○  Workbook Protection Block ➜ 5.18
    :protect      => 0x0012, # ○  PROTECT
                             #    Worksheet contents: 1 = protected (➜ 6.77)
    :windowprot   => 0x0019, # ○  WINDOWPROTECT Window settings: 1 = protected
                             #                  (BIFF4W only, ➜ 6.110)
    :objectprot   => 0x0063, # ○  OBJECTPROTECT
                             #    Embedded objects: 1 = protected (➜ 6.69)
    :scenprotect  => 0x00dd, # ○  SCENPROTECT
                             #    Scenarios: 1 = protected (BIFF5-BIFF8, ➜ 6.86)
    :password     => 0x0013, # ○  PASSWORD Hash value of the password;
                             #             0   = no password (➜ 6.72)
    ########################## ○  File Protection Block ➜ 5.19
    :writeprot    => 0x0086, # ○  WRITEPROT File is write protected
                             #    (BIFF3-BIFF8, ➜ 6.112), password in FILESHARING
    :filepass     => 0x002f, # ○  FILEPASS File is read/write-protected,
                             #             encryption information (➜ 6.41)
    :writeaccess  => 0x005c, # ○  WRITEACCESS User name (BIFF3-BIFF8, ➜ 6.111)
    :filesharing  => 0x005b, # ○  FILESHARING File sharing options
                             #    (BIFF3-BIFF8, ➜ 6.42)
    ########################## ○  Link Table ➜ 5.10.3
                             # ●● SUPBOOK Block(s)
                             #    Settings for a referenced document
    :supbook      => 0x01ae, #    ●  SUPBOOK ➜ 6.100
    :externname   => 0x0223, #    ○○ EXTERNNAME ➜ 6.38
    :xct          => 0x0059, #    ○○ ●  XCT ➜ 6.114
    :crn          => 0x005a, #       ●● CRN ➜ 6.24
    :externsheet  => 0x0017, # ●  EXTERNSHEET ➜ 6.39
    :name         => 0x0218, # ○○ NAME ➜ 6.66
    ##########################
    :window1      => 0x003d, # ●  WINDOW1 ➜ 6.108 (has information on
                             #              which Spreadsheet is 'active')
    :backup       => 0x0040, # ○  BACKUP ➜ 6.5
    :country      => 0x008c, # ○  COUNTRY (Make writeable?) ➜ 6.23
    :hideobj      => 0x008d, # ○  HIDEOBJ ➜ 6.52
    :palette      => 0x0092, # ○  PALETTE ➜ 6.70
    :fngroupcnt   => 0x009c, # ○  FNGROUPCOUNT
    :bookbool     => 0x00da, # ○  BOOKBOOL ➜ 6.9
    :tabid        => 0x013d, # ○  TABID
    :useselfs     => 0x0160, # ○  USESELFS (Natural Language Formulas) ➜ 6.105
    :dsf          => 0x0161, # ○  DSF (Double Stream File) ➜ 6.32
    :refreshall   => 0x01b7, # ○  REFRESHALL
    ########################## ●  Worksheet View Settings Block ➜ 5.5
    :window2      => 0x023e, # ●  WINDOW2 ➜ 5.110
    :scl          => 0x00a0, # ○  SCL ➜ 5.92 (BIFF4-BIFF8 only)
    :pane         => 0x0041, # ○  PANE ➜ 5.75
    :selection    => 0x001d, # ○○ SELECTION ➜ 5.93
    ########################## ○  Page Settings Block ➜ 5.4
    :hpagebreaks  => 0x001b, # ○  HORIZONTALPAGEBREAKS ➜ 6.54
    :vpagebreaks  => 0x001a, # ○  VERTICALPAGEBREAKS ➜ 6.107
    :header       => 0x0014, # ○  HEADER ➜ 6.51
    :footer       => 0x0015, # ○  FOOTER ➜ 6.44
    :hcenter      => 0x0083, # ○  HCENTER ➜ 6.50 (BIFF3-BIFF8 only)
    :vcenter      => 0x0084, # ○  VCENTER ➜ 6.106 (BIFF3-BIFF8 only)
    :leftmargin   => 0x0026, # ○  LEFTMARGIN ➜ 6.62
    :rightmargin  => 0x0027, # ○  RIGHTMARGIN ➜ 6.81
    :topmargin    => 0x0028, # ○  TOPMARGIN ➜ 6.103
    :bottommargin => 0x0029, # ○  BOTTOMMARGIN ➜ 6.11
                             # ○  PLS (opcode unknown)
    :pagesetup    => 0x00a1, # ○  PAGESETUP ➜ 6.89 (BIFF4-BIFF8 only)
    :bitmap       => 0x00e9, # ○  BITMAP ➜ 6.6 (Background-Bitmap, BIFF8 only)
    ##########################
    :printheaders => 0x002a, # ○  PRINTHEADERS ➜ 6.76
    :printgridlns => 0x002b, # ○  PRINTGRIDLINES ➜ 6.75
    :gridset      => 0x0082, # ○  GRIDSET ➜ 6.48
    :guts         => 0x0080, # ○  GUTS ➜ 6.49
    :defrowheight => 0x0225, # ○  DEFAULTROWHEIGHT ➜ 6.28
    :wsbool       => 0x0081, # ○  WSBOOL ➜ 6.113
    :defcolwidth  => 0x0055, # ○  DEFCOLWIDTH ➜ 6.29
    :sort         => 0x0090, # ○  SORT ➜ 6.95
    :note         => 0x001c,
    :obj          => 0x005d,
    :drawing      => 0x00EC,
    :txo          => 0x01B6,
  }
=begin ## unknown opcodes
0x00bf, 0x00c0, 0x00c1, 0x00e1, 0x00e2, 0x00eb, 0x01af, 0x01bc
=end
  SEDOCPO = OPCODES.invert
  TWIPS = 20
  UNDERLINE_TYPES = {
    0x0001 => :single,
    0x0002 => :double,
    0x0021 => :single_accounting,
    0x0022 => :double_accounting,
  }
  SEPYT_ENILREDNU = UNDERLINE_TYPES.invert
  XF_H_ALIGN = {
    :default       => 0,
    :left          => 1,
    :center        => 2,
    :right         => 3,
    :fill          => 4,
    :justify       => 5,
    :merge         => 6,
    :distributed   => 7,
  }
  NGILA_H_FX = XF_H_ALIGN.invert
  XF_TEXT_DIRECTION = {
    :context       => 0,
    :left_to_right => 1,
    :right_to_left => 2,
  }
  NOITCERID_TXET_FX = XF_TEXT_DIRECTION.invert
  XF_V_ALIGN = {
    :top         => 0,
    :middle      => 1,
    :bottom      => 2,
    :justify     => 3,
    :distributed => 4,
  }
  NGILA_V_FX = XF_V_ALIGN.invert
# border line styles taken from http://www.openoffice.org/sc/excelfileformat.pdf
	XF_BORDER_LINE_STYLES = {
		0x00	=>	:none,
		0x01	=>	:thin,
		0x02	=>	:medium,
		0x03	=>	:dashed,
		0x04	=>	:dotted,
		0x05	=>	:thick,
		0x06	=>	:double,
		0x07	=>	:hair,
# the following are only valid for BIFF8 and higher:
		0x08	=>	:medium_dashed,
		0x09	=>	:thin_dash_dotted,
		0x0a	=>	:medium_dash_dotted,
		0x0b	=>	:thin_dash_dot_dotted,
		0x0c	=>	:medium_dash_dot_dotted,
		0x0d	=>	:slanted_medium_dash_dotted
	}
# ensure reader always gets a valid line style
	XF_BORDER_LINE_STYLES.default = :none
	SELYTS_ENIL_REDROB_FX = XF_BORDER_LINE_STYLES.invert
	SELYTS_ENIL_REDROB_FX.default = 0x00
  OPCODE_SIZE = 4
  ROW_HEIGHT = 12.1
  SST_CHUNKSIZE = 20
  def binfmt key
    BINARY_FORMATS[key]
  end
  def opcode key
    OPCODES[key]
  end
end
  end
end

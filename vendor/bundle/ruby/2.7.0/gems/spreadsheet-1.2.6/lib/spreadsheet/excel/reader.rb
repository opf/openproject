require 'spreadsheet/encodings'
require 'spreadsheet/font'
require 'spreadsheet/formula'
require 'spreadsheet/link'
require 'spreadsheet/note'
require 'spreadsheet/noteObject'
require 'spreadsheet/excel/error'
require 'spreadsheet/excel/internals'
require 'spreadsheet/excel/sst_entry'
require 'spreadsheet/excel/worksheet'

module Spreadsheet
  module Excel
##
# Reader class for Excel Workbooks. Most read_* method correspond to an
# Excel-Record/Opcode. You should not need to call any of its methods
# directly. If you think you do, look at #read
class Reader
  include Spreadsheet::Encodings
  include Spreadsheet::Excel::Internals
  ROW_BLOCK_OPS = {
    :blank  => true, :boolerr  => true, :dbcell   => true, :formula => true,
    :label  => true, :labelsst => true, :mulblank => true, :mulrk   => true,
    :number => true, :rk       => true, :rstring  => true,
  }
  def initialize opts = {}
    @pos = 0
    @bigendian = opts.fetch(:bigendian) {
      [1].pack('l') != "\001\000\000\000"
    }
    @opts = opts
    @boundsheets = nil
    @current_row_block = {}
    @current_row_block_offset = nil
    @formats = {}
    BUILTIN_FORMATS.each do |key, fmt| @formats.store key, client(fmt, 'UTF-8') end
  end
  def decode_rk work
    #  Bit  Mask        Contents
    #    0  0x00000001  0 = Value not changed 1 = Value is multiplied by 100
    #    1  0x00000002  0 = Floating-point value 1 = Signed integer value
    # 31-2  0xFFFFFFFC  Encoded value
    #
    # If bit 1 is cleared, the encoded value represents the 30 most significant
    # bits of an IEEE 754 floating-point value (64-bit double precision). The
    # 34 least significant bits must be set to zero. If bit 1 is set, the
    # encoded value represents a signed 30-bit integer value. To get the
    # correct integer, the encoded value has to be shifted right arithmetically
    # by 2 bits. If bit 0 is set, the decoded value (both integer and
    # floating-point) must be divided by 100 to get the final result.
    flags, = work.unpack 'C'
    cent = flags & 1
    int  = flags & 2
    value = 0
    if int == 0
      ## remove two bits
      integer, = work.unpack 'V'
      integer &= 0xfffffffc
      value, = ("\0\0\0\0" +  [integer].pack('V')).unpack EIGHT_BYTE_DOUBLE
    else
      ## I can't find a format for unpacking a little endian signed integer.
      #  'V' works for packing, but not for unpacking. But the following works
      #  fine afaics:
      unsigned, = (@bigendian ? work.reverse : work).unpack 'l'
      ## remove two bits
      value = unsigned >> 2
    end
    if cent == 1
      value /= 100.0
    end
    value
  end
  def encoding codepage_id
    name = CODEPAGES.fetch(codepage_id) do
      raise Spreadsheet::Errors::UnknownCodepage, "Unknown Codepage 0x%04x" % codepage_id
    end

    if RUBY_VERSION >= '1.9'
      begin
        Encoding.find name
      rescue ArgumentError
        raise Spreadsheet::Errors::UnsupportedEncoding, "Unsupported encoding with name '#{name}'"
      end
    else
      name
    end
  end
  def get_next_chunk
    pos = @pos
    if pos < @data.size
      op, len = @data[@pos,OPCODE_SIZE].unpack('v2')
      @pos += OPCODE_SIZE
      if len
        work = @data[@pos,len]
        @pos += len
        code = SEDOCPO.fetch(op, op)
        if io = @opts[:print_opcodes]
          io.puts sprintf("0x%04x/%-16s %5i: %s",
                          op, code.inspect, len, work.inspect)
        end
        [ pos, code, len + OPCODE_SIZE, work]
      end
    end
  end
  def in_row_block? op, previous
    if op == :row
      previous == op
    else
      ROW_BLOCK_OPS.include?(op)
    end
  end
  def memoize?
    @opts[:memoization]
  end
  def postread_workbook
    sheets = @workbook.worksheets
    sheets.each_with_index do |sheet, idx|
      offset = sheet.offset
      nxt = (nxtsheet = sheets[idx + 1]) ? nxtsheet.offset : @workbook.ole.size
      @workbook.offsets.store sheet, [offset, nxt - offset]
    end
  end
  def postread_worksheet worksheet
     #We now have a lot of Note and NoteObjects, but they're not linked
     #So link the noteObject(text) to the note (with author, position)
     #TODO
     @noteList.each do |i|
        matching_objs = @noteObjList.select { |j| j.objID == i.objID }
        if matching_objs.length > 1
           puts "ERROR - more than one matching object ID!"
        end
        matching_obj = matching_objs.first
        i.text = matching_obj.nil? ? '' : matching_obj.text
        worksheet.add_note i.row, i.col, i.text
     end
  end
  ##
  # The entry-point for reading Excel-documents. Reads the Biff-Version and
  # loads additional reader-methods before proceeding with parsing the document.
  def read io
    setup io
    read_workbook
    @workbook.default_format = @workbook.format 0
    @workbook.changes.clear
    @workbook
  end
  def read_blank worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    row, column, xf = work.unpack binfmt(:blank)
    set_cell worksheet, row, column, xf
  end
  def read_bof
    # Offset  Size  Contents
    #      0     2  BIFF version (always 0x0600 for BIFF8)
    #      2     2  Type of the following data: 0x0005 = Workbook globals
    #                                           0x0006 = Visual Basic module
    #                                           0x0010 = Worksheet
    #                                           0x0020 = Chart
    #                                           0x0040 = Macro sheet
    #                                           0x0100 = Workspace file
    #      4     2  Build identifier
    #      6     2  Build year
    #      8     4  File history flags
    #     12     4  Lowest Excel version that can read all records in this file
    _, @bof, _, work = get_next_chunk
    ## version and datatype are common to all Excel-Versions. Later versions
    #  have additional information such as build-id and -year (from BIFF5).
    #  These are ignored for the time being.
    version, datatype = work.unpack('v2')
    if datatype == 0x5
      @version = version
    end
  end
  def read_boolerr worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    #      6     1  Boolean or error value (type depends on the following byte)
    #      7     1  0 = Boolean value; 1 = Error code
    row, column, xf, value, error = work.unpack 'v3C2'
    set_cell worksheet, row, column, xf, error == 0 ? value > 0 : Error.new(value)
  end
  def read_boundsheet work, pos, len
    # Offset  Size  Contents
    #      0     4  Absolute stream position of the BOF record of the sheet
    #               represented by this record. This field is never encrypted
    #               in protected files.
    #      4     1  Visibility: 0x00 = Visible
    #                           0x01 = Hidden
    #                           0x02 = Strong hidden (see below)
    #      5     1  Sheet type: 0x00 = Worksheet
    #                           0x02 = Chart
    #                           0x06 = Visual Basic module
    #      6  var.  Sheet name: BIFF5/BIFF7: Byte string,
    #                           8-bit string length (➜ 3.3)
    #                           BIFF8: Unicode string, 8-bit string length (➜ 3.4)
    offset, visibility, _ = work.unpack("VC2")
    name = client read_string(work[6..-1]), @workbook.encoding
    if @boundsheets
      @boundsheets[0] += 1
      @boundsheets[2] += len
    else
      @boundsheets = [1, pos, len]
    end
    @workbook.set_boundsheets(*@boundsheets)
    @workbook.add_worksheet Worksheet.new(:name     => name,
                                          :ole      => @book,
                                          :offset   => offset,
                                          :reader   => self,
                                          :visibility => WORKSHEET_VISIBILITIES[visibility])
  end
  def read_codepage work, pos, len
    codepage, _ = work.unpack 'v'
    @workbook.set_encoding encoding(codepage), pos, len
  end
  def read_colinfo worksheet, work, pos, len
    # Offset  Size  Contents
    #      0     2  Index to first column in the range
    #      2     2  Index to last column in the range
    #      4     2  Width of the columns in 1/256 of the width of the zero
    #               character, using default font (first FONT record in the
    #               file)
    #      6     2  Index to XF record (➜ 6.115) for default column formatting
    #      8     2  Option flags:
    #               Bits  Mask    Contents
    #                  0  0x0001  1 = Columns are hidden
    #               10-8  0x0700  Outline level of the columns (0 = no outline)
    #                 12  0x1000  1 = Columns are collapsed
    #     10     2  Not used
    first, last, width, xf, opts = work.unpack binfmt(:colinfo)[0..-2]
    first.upto last do |col|
      column = Column.new col, @workbook.format(xf),
                          :width         => width.to_f / 256,
                          :hidden        => (opts & 0x0001) > 0,
                          :collapsed     => (opts & 0x1000) > 0,
                          :outline_level => (opts & 0x0700) / 256
      column.worksheet = worksheet
      worksheet.columns[col] = column
    end
  end
  def read_dimensions worksheet, work, pos, len
    # Offset  Size  Contents
    #      0     4  Index to first used row
    #      4     4  Index to last used row, increased by 1
    #      8     2  Index to first used column
    #     10     2  Index to last used column, increased by 1
    #     12     2  Not used
    worksheet.set_dimensions work.unpack(binfmt(:dimensions)), pos, len
  end
  def read_font work, pos, len
    # Offset  Size  Contents
    #      0     2  Height of the font (in twips = 1/20 of a point)
    #      2     2  Option flags:
    #               Bit  Mask    Contents
    #                 0  0x0001  1 = Characters are bold (redundant, see below)
    #                 1  0x0002  1 = Characters are italic
    #                 2  0x0004  1 = Characters are underlined
    #                                (redundant, see below)
    #                 3  0x0008  1 = Characters are struck out
    #                 4  0x0010  1 = Characters are outlined (djberger)
    #                 5  0x0020  1 = Characters are shadowed (djberger)
    #      4     2  Colour index (➜ 6.70)
    #      6     2  Font weight (100-1000). Standard values are
    #                           0x0190 (400) for normal text and
    #                           0x02bc (700) for bold text.
    #      8     2  Escapement type: 0x0000 = None
    #                                0x0001 = Superscript
    #                                0x0002 = Subscript
    #     10     1  Underline type: 0x00 = None
    #                               0x01 = Single
    #                               0x02 = Double
    #                               0x21 = Single accounting
    #                               0x22 = Double accounting
    #     11     1  Font family:
    #               0x00 = None (unknown or don't care)
    #               0x01 = Roman (variable width, serifed)
    #               0x02 = Swiss (variable width, sans-serifed)
    #               0x03 = Modern (fixed width, serifed or sans-serifed)
    #               0x04 = Script (cursive)
    #               0x05 = Decorative (specialised,
    #                                  for example Old English, Fraktur)
    #     12     1  Character set: 0x00 =   0 = ANSI Latin
    #                              0x01 =   1 = System default
    #                              0x02 =   2 = Symbol
    #                              0x4d =  77 = Apple Roman
    #                              0x80 = 128 = ANSI Japanese Shift-JIS
    #                              0x81 = 129 = ANSI Korean (Hangul)
    #                              0x82 = 130 = ANSI Korean (Johab)
    #                              0x86 = 134 = ANSI Chinese Simplified GBK
    #                              0x88 = 136 = ANSI Chinese Traditional BIG5
    #                              0xa1 = 161 = ANSI Greek
    #                              0xa2 = 162 = ANSI Turkish
    #                              0xa3 = 163 = ANSI Vietnamese
    #                              0xb1 = 177 = ANSI Hebrew
    #                              0xb2 = 178 = ANSI Arabic
    #                              0xba = 186 = ANSI Baltic
    #                              0xcc = 204 = ANSI Cyrillic
    #                              0xde = 222 = ANSI Thai
    #                              0xee = 238 = ANSI Latin II (Central European)
    #                              0xff = 255 = OEM Latin I
    #     13     1  Not used
    #     14  var.  Font name:
    #               BIFF5/BIFF7: Byte string, 8-bit string length (➜ 3.3)
    #               BIFF8: Unicode string, 8-bit string length (➜ 3.4)
    name = client read_string(work[14..-1]), @workbook.encoding
    font = Font.new name
    size, opts, color, font.weight, escapement, underline,
      family, encoding = work.unpack binfmt(:font)
    font.size       = size / TWIPS
    font.italic     = opts & 0x0002
    font.strikeout  = opts & 0x0008
    font.outline    = opts & 0x0010
    font.shadow     = opts & 0x0020
    font.color      = COLOR_CODES[color] || :text
    font.escapement = ESCAPEMENT_TYPES[escapement]
    font.underline  = UNDERLINE_TYPES[underline]
    font.family     = FONT_FAMILIES[family]
    font.encoding   = FONT_ENCODINGS[encoding]
    @workbook.add_font font
  end
  def read_format work, pos, len
    # Offset  Size  Contents
    #      0     2  Format index used in other records
    #      2  var.  Number format string
    #               (Unicode string, 16-bit string length, ➜ 3.4)
    idx, = work.unpack 'v'
    value = read_string work[2..-1], 2
    @formats.store idx, client(value, @workbook.encoding)
  end
  def read_formula worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    #      6     8  Result of the formula. See below for details.
    #     14     2  Option flags:
    #               Bit  Mask    Contents
    #                 0  0x0001  1 = Recalculate always
    #                 1  0x0002  1 = Calculate on open
    #                 3  0x0008  1 = Part of a shared formula
    #     16     4  Not used
    #     20  var.  Formula data (RPN token array, ➜ 4)
    #               Offset  Size  Contents
    #                    0     2  Size of the following formula data (sz)
    #                    2    sz  Formula data (RPN token array)
    #               [2+sz]  var.  (optional) Additional data for specific tokens
    #                             (➜ 4.1.6, for example tArray token, ➜ 4.8.7)
    #
    # Result of the Formula
    # Dependent on the type of value the formula returns, the result field has
    # the following format:
    #
    # Result is a numeric value:
    # Offset  Size  Contents
    #      0     8  IEEE 754 floating-point value (64-bit double precision)
    #
    # Result is a string (the string follows in a STRING record, ➜ 6.98):
    # Offset  Size  Contents
    #      0     1  0x00 (identifier for a string value)
    #      1     5  Not used
    #      6     2  0xffff
    # Note: In BIFF8 the string must not be empty. For empty cells there is a
    # special identifier defined (see below).
    #
    # Result is a Boolean value:
    # Offset  Size  Contents
    #      0     1  0x01 (identifier for a Boolean value)
    #      1     1  Not used
    #      2     1  0 = FALSE, 1 = TRUE
    #      3     3  Not used
    #      6     2  0xffff
    #
    # Result is an error value:
    # Offset  Size  Contents
    #      0     1  0x02 (identifier for an error value)
    #      1     1  Not used
    #      2     1  Error code (➜ 3.7)
    #      3     3  Not used
    #      6     2  0xffff
    #
    # Result is an empty cell (BIFF8), for example an empty string:
    # Offset  Size  Contents
    #      0     1  0x03 (identifier for an empty cell)
    #      1     5  Not used
    #      6     2  0xffff
    row, column, xf, rtype, rval, rcheck, opts = work.unpack 'v3CxCx3v2'
    formula = Formula.new
    formula.shared = (opts & 0x08) > 0
    formula.data = work[20..-1]
    if rcheck != 0xffff || rtype > 3
      value, = work.unpack 'x6E'
      unless value
        # on architectures where sizeof(double) > 8
        value, = work.unpack 'x6e'
      end
      formula.value = value
    elsif rtype == 0
      pos, op, _len, work = get_next_chunk
      if op == :sharedfmla
        ## TODO: formula-support in 0.8.0
        pos, op, _len, work = get_next_chunk
      end
      if op == :string
        formula.value = client read_string(work, 2), @workbook.encoding
      else
        warn "String Value expected after Formula, but got #{op}"
        formula.value = Error.new 0x2a
        @pos = pos
      end
    elsif rtype == 1
      formula.value = rval > 0
    elsif rtype == 2
      formula.value = Error.new rval
    else
      # leave the Formula value blank
    end
    set_cell worksheet, row, column, xf, formula
  end
  def read_hlink worksheet, work, pos, len
    # 6.53.1 Common Record Contents
    # Offset  Size  Contents
    #      0     8  Cell range address of all cells containing this hyperlink
    #               (➜ 3.13.1)
    #      8    16  GUID of StdLink:
    #               D0 C9 EA 79 F9 BA CE 11 8C 82 00 AA 00 4B A9 0B
    #               (79EAC9D0-BAF9-11CE-8C82-00AA004BA90B)
    #     24     4  Unknown value: 0x00000002
    #     28     4  Option flags (see below)
    #               Bit  Mask        Contents
    #                 0  0x00000001  0 = No link extant
    #                                1 = File link or URL
    #                 1  0x00000002  0 = Relative file path
    #                                1 = Absolute path or URL
    #           2 and 4  0x00000014  0 = No description
    #                                1 (both bits) = Description
    #                 3  0x00000008  0 = No text mark
    #                                1 = Text mark
    #                 7  0x00000080  0 = No target frame
    #                                1 = Target frame
    #                 8  0x00000100  0 = File link or URL
    #                                1 = UNC path (incl. server name)
    #--------------------------------------------------------------------------
    #   [32]     4  (optional, see option flags) Character count of description
    #               text, including trailing zero word (dl)
    #   [36]  2∙dl  (optional, see option flags) Character array of description
    #               text, no Unicode string header, always 16-bit characters,
    #               zero-terminated
    #--------------------------------------------------------------------------
    # [var.]     4  (optional, see option flags) Character count of target
    #               frame, including trailing zero word (fl)
    # [var.]  2∙fl  (optional, see option flags) Character array of target
    #               frame, no Unicode string header, always 16-bit characters,
    #               zero-terminated
    #--------------------------------------------------------------------------
    #   var.  var.  Special data (➜ 6.53.2 and following)
    #--------------------------------------------------------------------------
    # [var.]     4  (optional, see option flags) Character count of the text
    #               mark, including trailing zero word (tl)
    # [var.]  2∙tl  (optional, see option flags) Character array of the text
    #               mark without “#” sign, no Unicode string header, always
    #               16-bit characters, zero-terminated
    firstrow, lastrow, firstcol, lastcol, _, opts = work.unpack 'v4H32x4V'
    has_link = opts & 0x0001
    desc     = opts & 0x0014
    textmark = opts & 0x0008
    target   = opts & 0x0080
    unc      = opts & 0x0100
    link = Link.new
    _, description = nil
    pos = 32
    if desc > 0
      description, pos = read_hlink_string work, pos
      link << description
    end
    if target > 0
      link.target_frame, pos = read_hlink_string work, pos
    end
    if unc > 0
      # 6.53.4 Hyperlink to a File with UNC (Universal Naming Convention) Path
      # These data fields are for UNC paths containing a server name (for
      # instance “\\server\path\file.xls”). The lower 9 bits of the option
      # flags field must be 1.x00x.xx112.
      # Offset  Size  Contents
      #      0     4  Character count of the UNC,
      #               including trailing zero word (fl)
      #      4  2∙fl  Character array of the UNC, no Unicode string header,
      #               always 16-bit characters, zeroterminated.
      link.url, pos = read_hlink_string work, pos
    elsif has_link > 0
      uid, = work.unpack "x#{pos}H32"
      pos += 16
      if uid == "e0c9ea79f9bace118c8200aa004ba90b"
        # 6.53.2 Hyperlink containing a URL (Uniform Resource Locator)
        # These data fields occur for links which are not local files or files
        # in the local network (for instance HTTP and FTP links and e-mail
        # addresses). The lower 9 bits of the option flags field must be
        # 0.x00x.xx112 (x means optional, depending on hyperlink content). The
        # GUID could be used to distinguish a URL from a file link.
        # Offset  Size  Contents
        #      0    16  GUID of URL Moniker:
        #               E0 C9 EA 79 F9 BA CE 11 8C 82 00 AA 00 4B A9 0B
        #               (79EAC9E0-BAF9-11CE-8C82-00AA004BA90B)
        #     16     4  Size of character array of the URL, including trailing
        #               zero word (us). There are us/2-1 characters in the
        #               following string.
        #     20    us  Character array of the URL, no Unicode string header,
        #               always 16-bit characters, zeroterminated
        size, = work.unpack "x#{pos}V"
        pos += 4
        data = work[pos, size].chomp "\000\000"
        link.url = client data
        pos += size
      else
        # 6.53.3 Hyperlink to a Local File
        # These data fields are for links to files on local drives. The path of
        # the file can be complete with drive letter (absolute) or relative to
        # the location of the workbook. The lower 9 bits of the option flags
        # field must be 0.x00x.xxx12. The GUID could be used to distinguish a
        # URL from a file link.
        # Offset  Size  Contents
        #      0    16  GUID of File Moniker:
        #               03 03 00 00 00 00 00 00 C0 00 00 00 00 00 00 46
        #               (00000303-0000-0000-C000-000000000046)
        #     16     2  Directory up-level count. Each leading “..\” in the
        #               file link is deleted and increases this counter.
        #     18     4  Character count of the shortened file path and name,
        #               including trailing zero byte (sl)
        #     22    sl  Character array of the shortened file path and name in
        #               8.3-DOS-format. This field can be filled with a long
        #               file name too. No Unicode string header, always 8-bit
        #               characters, zeroterminated.
        #  22+sl    24  Unknown byte sequence:
        #               FF FF AD DE 00 00 00 00
        #               00 00 00 00 00 00 00 00
        #               00 00 00 00 00 00 00 00
        #  46+sl     4  Size of the following file link field including string
        #               length field and additional data field (sz). If sz is
        #               zero, nothing will follow (except a text mark).
        # [50+sl]    4  (optional) Size of character array of the extended file
        #               path and name (xl). There are xl/2 characters in the
        #               following string.
        # [54+sl]    2  (optional) Unknown byte sequence: 03 00
        # [56+sl]   xl  (optional) Character array of the extended file path
        #               and name (xl), no Unicode string header, always 16-bit
        #               characters, not zero-terminated
        uplevel, count = work.unpack "x#{pos}vV"
        pos += 6
        # TODO: short file path may have any of the OEM encodings. Find out which
        #       and use the #client method to convert the encoding.
        prefix = internal('..\\', 'UTF-8') * uplevel
        link.dos = link.url = prefix << work[pos, count].chomp("\000")
        pos += count + 24
        total, size = work.unpack "x#{pos}V2"
        pos += 10
        if total > 0
          link.url = client work[pos, size]
          pos += size
        end
      end
    else
      # 6.53.5 Hyperlink to the Current Workbook
      # In this case only the text mark field is present (optional with
      # description).
      # Example: The URL “#Sheet2!B1:C2” refers to the given range in the
      # current workbook.
      # The lower 9 bits of the option flags field must be 0.x00x.1x002.
    end
    if textmark > 0
      link.fragment, _ = read_hlink_string work, pos
    end
    if link.empty?
      link << link.href
    end
    firstrow.upto lastrow do |row|
      firstcol.upto lastcol do |col|
        worksheet.add_link row, col, link
      end
    end
  end
  def read_hlink_string work, pos
    count, = work.unpack "x#{pos}V"
    len = count * 2
    pos += 4
    data = work[pos, len].chomp "\000\000"
    pos += len
    [client(data, 'UTF-16LE'), pos]
  end
  def read_index worksheet, work, pos, len
    # Offset  Size  Contents
    #      0     4  Not used
    #      4     4  Index to first used row (rf, 0-based)
    #      8     4  Index to first row of unused tail of sheet
    #               (rl, last used row + 1, 0-based)
    #     12     4  Absolute stream position of the
    #               DEFCOLWIDTH record (➜ 6.29) of the current sheet. If this
    #               record does not exist, the offset points to the record at
    #               the position where the DEFCOLWIDTH record would occur.
    #     16  4∙nm  Array of nm absolute stream positions to the
    #               DBCELL record (➜ 6.26) of each Row Block
    # TODO: use the index if it exists
    # _, first_used, first_unused, defcolwidth, *indices = work.unpack 'V*'
  end
  def read_label worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    #      6  var.  Unicode string, 16-bit string length (➜ 3.4)
    row, column, xf = work.unpack 'v3'
    value = client read_string(work[6..-1], 2), @workbook.encoding
    set_cell worksheet, row, column, xf, value
  end
  def read_labelsst worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    #      6     4  Index into SST record (➜ 6.96)
    row, column, xf, index = work.unpack binfmt(:labelsst)
    set_cell worksheet, row, column, xf, worksheet.shared_string(index)
  end
  def read_mulblank worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to first column (fc)
    #      4  2∙nc  List of nc=lc-fc+1 16-bit indexes to XF records (➜ 6.115)
    # 4+2∙nc     2  Index to last column (lc)
    row, column, *xfs = work.unpack 'v*'
    xfs.pop #=> last_column
    xfs.each_with_index do |xf, idx| set_cell worksheet, row, column + idx, xf end
  end
  def read_mulrk worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to first column (fc)
    #      4  6∙nc  List of nc=lc-fc+1 XF/RK structures. Each XF/RK contains:
    #               Offset  Size  Contents
    #                    0     2  Index to XF record (➜ 6.115)
    #                    2     4  RK value (➜ 3.6)
    # 4+6∙nc     2  Index to last column (lc)
    row, column = work.unpack 'v2'
    4.step(work.size - 6, 6) do |idx|
      xf, = work.unpack "x#{idx}v"
      set_cell worksheet, row, column, xf, decode_rk(work[idx + 2, 4])
      column += 1
    end
  end
  def read_number worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    #      6     8  IEEE 754 floating-point value (64-bit double precision)
    row, column, xf, value = work.unpack binfmt(:number)
    set_cell worksheet, row, column, xf, value
  end
  def read_rk worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    #      6     4  RK value (➜ 3.6)
    row, column, xf = work.unpack 'v3'
    set_cell worksheet, row, column, xf, decode_rk(work[6,4])
  end
  def read_row worksheet, addr
    row = addr[:index]
    @current_row_block.fetch [worksheet, row] do
      @current_row_block.clear
      cells = @current_row_block[[worksheet, row]] = Row.new(nil, row)
      @pos = addr[:offset]
      found = false
      while tuple = get_next_chunk
        pos, op, _, work = tuple
        case op
        when :eof      # ●  EOF ➜ 6.36 - we should only get here if there is just
                       #                 one Row-Block
          @pos = pos
          return cells
        when :dbcell   # ○  DBCELL Stream offsets to the cell records of each row
          return cells
        when :row      # ○○ Row Blocks ➜ 5.7
                       # ●  ROW ➜ 6.83
          # ignore, we already did these in read_worksheet
          return cells if found
        when :blank    # BLANK ➜ 6.7
          found = true
          read_blank worksheet, addr, work
        when :boolerr  # BOOLERR ➜ 6.10
          found = true
          read_boolerr worksheet, addr, work
        when 0x0002    # INTEGER ➜ 6.56 (BIFF2 only)
          found = true
          # TODO: implement for BIFF2 support
        when :formula  # FORMULA ➜ 6.46
          found = true
          read_formula worksheet, addr, work
        when :label    # LABEL ➜ 6.59 (BIFF2-BIFF7)
          found = true
          read_label worksheet, addr, work
        when :labelsst # LABELSST ➜ 6.61 (BIFF8 only)
          found = true
          read_labelsst worksheet, addr, work
        when :mulblank # MULBLANK ➜ 6.64 (BIFF5-BIFF8)
          found = true
          read_mulblank worksheet, addr, work
        when :mulrk    # MULRK ➜ 6.65 (BIFF5-BIFF8)
          found = true
          read_mulrk worksheet, addr, work
        when :number   # NUMBER ➜ 6.68
          found = true
          read_number worksheet, addr, work
        when :rk       # RK ➜ 6.82 (BIFF3-BIFF8)
          found = true
          read_rk worksheet, addr, work
        when :rstring  # RSTRING ➜ 6.84 (BIFF5/BIFF7)
          found = true
          read_rstring worksheet, addr, work
        end
      end
      cells
    end
  end
  def read_rstring worksheet, addr, work
    # Offset  Size  Contents
    #      0     2  Index to row
    #      2     2  Index to column
    #      4     2  Index to XF record (➜ 6.115)
    #      6    sz  Unformatted Unicode string, 16-bit string length (➜ 3.4)
    #   6+sz     2  Number of Rich-Text formatting runs (rt)
    #   8+sz  4·rt  List of rt formatting runs (➜ 3.2)
    row, column, xf = work.unpack 'v3'
    value = client read_string(work[6..-1], 2), @workbook.encoding
    set_cell worksheet, row, column, xf, value
  end
  def read_window2 worksheet, work, pos, len
    # This record contains additional settings for the document window
    # (BIFF2-BIFF4) or for the window of a specific worksheet (BIFF5-BIFF8).
    # It is part of the Sheet View Settings Block (➜ 4.5).
    # Offset  Size  Contents
    #      0     2  Option flags:
    #               Bits  Mask    Contents
    #                  0  0x0001  0 = Show formula results
    #                             1 = Show formulas
    #                  1  0x0002  0 = Do not show grid lines
    #                             1 = Show grid lines
    #                  2  0x0004  0 = Do not show sheet headers
    #                             1 = Show sheet headers
    #                  3  0x0008  0 = Panes are not frozen
    #                             1 = Panes are frozen (freeze)
    #                  4  0x0010  0 = Show zero values as empty cells
    #                             1 = Show zero values
    #                  5  0x0020  0 = Manual grid line colour
    #                             1 = Automatic grid line colour
    #                  6  0x0040  0 = Columns from left to right
    #                             1 = Columns from right to left
    #                  7  0x0080  0 = Do not show outline symbols
    #                             1 = Show outline symbols
    #                  8  0x0100  0 = Keep splits if pane freeze is removed
    #                             1 = Remove splits if pane freeze is removed
    #                  9  0x0200  0 = Sheet not selected
    #                             1 = Sheet selected (BIFF5-BIFF8)
    #                 10  0x0400  0 = Sheet not active
    #                             1 = Sheet active (BIFF5-BIFF8)
    #                 11  0x0800  0 = Show in normal view
    #                             1 = Show in page break preview (BIFF8)
    #      2     2  Index to first visible row
    #      4     2  Index to first visible column
    #      6     2  Colour index of grid line colour (➜ 5.74).
    #               Note that in BIFF2-BIFF5 an RGB colour is written instead.
    #      8     2  Not used
    #     10     2  Cached magnification factor in page break preview (in percent)
    #               0 = Default (60%)
    #     12     2  Cached magnification factor in normal view (in percent)
    #               0 = Default (100%)
    #     14     4  Not used
    flags, _ = work.unpack 'v'
    worksheet.selected = flags & 0x0200 > 0
  end

  def read_merged_cells worksheet, work, pos, len
    # This record contains the addresses of merged cell ranges in the current sheet.
    # Record MERGEDCELLS, BIFF8:
    # Offset  Size  Contents
    # 0	      var.	Cell range address list with merged ranges (➜ 2.5.15)
    # If the record size exceeds the limit, it is not continued with a CONTINUE record,
    # but another self-contained MERGEDCELLS record is started. The limit of 8224 bytes
    # per record results in a maximum number of 1027 merged ranges.

    worksheet.merged_cells.push(*read_range_address_list(work, len))
    #
    # A cell range address list consists of a field with the number of ranges and the list
    # of the range addresses.
    # Cell range address list, BIFF2-BIFF8:
    # Offset  Size          Contents
    # 0       2             Number of following cell range addresses (nm)
    # 2	      6∙nm or 8∙nm  List of nm cell range addresses (➜ 2.5.14)
    #
  end

  def read_workbook
    previous_op = nil
    while tuple = get_next_chunk
      pos, op, len, work = tuple
      case op
      when @bof, :bof  # ●  BOF Type = worksheet (➜ 6.8)
        return
      when :eof        # ●  EOF ➜ 6.36
        postread_workbook
        return
      when :datemode   # ○  DATEMODE ➜ 6.25
        flag, _ = work.unpack 'v'
        if flag == 1
          @workbook.date_base = DateTime.new 1904, 1, 1
        else
          @workbook.date_base = DateTime.new 1899, 12, 31
        end
      when :continue   # ○  CONTINUE ➜ 6.22
        case previous_op
        when :sst      # ●  SST ➜ 6.96
          continue_sst work, pos, len
        end
      when :codepage   # ○  CODEPAGE ➜ 6.17
        read_codepage work, pos, len
      when :boundsheet # ●● BOUNDSHEET ➜ 6.12
        read_boundsheet work, pos, len
      when :xf         # ●● XF ➜ 6.115
        read_xf work, pos, len
      when :sst        # ○  Shared String Table ➜ 5.11
                       # ●  SST ➜ 6.96
        read_sst work, pos, len
        # TODO: implement memory-efficient sst handling, possibly in conjunction
        #       with EXTSST
      when :extsst     # ●  EXTSST ➜ 6.40
        read_extsst work, pos, len
      when :style      # ●● STYLE ➜ 6.99
        read_style work, pos, len
      when :format     # ○○ FORMAT (Number Format) ➜ 6.45
        read_format work, pos, len
      when :font       # ●● FONT ➜ 6.43
        read_font work, pos, len
      end
      previous_op = op unless op == :continue
    end
  end
  def read_worksheet worksheet, offset
    @pos = offset
    @detected_rows = {}
    @noteObjList = []
    @noteList = []
    @noteObject = nil
    previous = nil
    while tuple = get_next_chunk
      pos, op, len, work = tuple
      if((offset = @current_row_block_offset) && !in_row_block?(op, previous))
        @current_row_block_offset = nil
        offset[1] = pos - offset[0]
      end
      case op
      when :eof        # ●  EOF ➜ 6.36
        postread_worksheet worksheet
        return
      #when :uncalced   # ○  UNCALCED ➜ 6.104
        # TODO: Formula support. Values were not calculated before saving
        #warn <<-EOS
        #  Some fields containig formulas were saved without a computed value.
        #  Support Spreadsheet::Excel by implementing formula-calculations!
        #EOS
      #when :index      # ○  INDEX ➜ 5.7 (Row Blocks), ➜ 6.55
        # TODO: if there are changes in rows, omit index when writing
        #read_index worksheet, work, pos, len
      when :guts       #    GUTS      5.53
        read_guts worksheet, work, pos, len
      when :colinfo    # ○○ COLINFO ➜ 6.18
        read_colinfo worksheet, work, pos, len
      when :dimensions # ●  DIMENSIONS ➜ 6.31
        read_dimensions worksheet, work, pos, len
      when :row        # ○○ Row Blocks ➜ 5.7
                       # ●  ROW ➜ 6.83
        set_row_address worksheet, work, pos, len
      when :hlink
        read_hlink worksheet, work, pos, len
      when :window2
        read_window2 worksheet, work, pos, len
      when :mergedcells # ○○ MERGEDCELLS	➜ 5.67
        read_merged_cells worksheet, work, pos, len
      when :protect, :password
        read_sheet_protection worksheet, op, work
      when :note # a note references an :obj
        read_note worksheet, work, pos, len
      when :obj # it contains the author in the NTS structure
        _ft, _cb, _ot, _objID = work.unpack('v4')
        if _ot == 0x19
          #puts "\nDEBUG: found Note Obj record"
          @noteObject         = NoteObject.new
          @noteObject.objID   = _objID
        end
        #p work
      when :drawing # this can be followed by txo in case of a note
        if previous == :obj
          #puts "\nDEBUG: found MsDrawing record"
          #p work
        end
      when :txo # this contains the length of the note text
        if previous == :drawing
          #puts "\nDEBUG: found TxO record"
          #p work
        end
      when :continue # this contains the actual note text
        if previous == :txo && @noteObject
          #puts "\nDEBUG: found Continue record"
          continueFmt = work.unpack('C')
          if (continueFmt.first == 0)
             #puts "Picking compressed charset"
             #Skip to offset due to 'v5C' used above
             _text = work.unpack('@1C*')
             @noteObject.text = _text.pack('C*')
          elsif (continueFmt.first == 1)
             #puts "Picking uncompressed charset"
             _text = work.unpack('@1S*')
             @noteObject.text = _text.pack('U*')
          end
          @noteObjList << @noteObject
        end
      when :pagesetup
        read_pagesetup(worksheet, work, pos, len)
      when :leftmargin
        worksheet.margins[:left] = work.unpack(binfmt(:margin))[0]
      when :rightmargin
        worksheet.margins[:right] = work.unpack(binfmt(:margin))[0]
      when :topmargin
        worksheet.margins[:top] = work.unpack(binfmt(:margin))[0]
      when :bottommargin
        worksheet.margins[:bottom] = work.unpack(binfmt(:margin))[0]
      else
        if ROW_BLOCK_OPS.include?(op)
          set_missing_row_address worksheet, work, pos, len
        end
      end
      previous = op
      #previous = op unless op == :continue
    end
  end

  def read_pagesetup(worksheet, work, pos, len)
    worksheet.pagesetup.delete_if { true }
    data = work.unpack(binfmt(:pagesetup))
    worksheet.pagesetup[:orientation] = data[5] == 0 ? :landscape : :portrait
    worksheet.pagesetup[:adjust_to] = data[1]

    worksheet.pagesetup[:orig_data] = data
    # TODO: add options acording to specification
  end

  def read_guts worksheet, work, pos, len
    # Offset Size Contents
    #      0    2 Width of the area to display row outlines (left of the sheet), in pixel
    #      2    2 Height of the area to display column outlines (above the sheet), in pixel
    #      4    2 Number of visible row outline levels (used row levels + 1; or 0, if not used)
    #      6    2 Number of visible column outline levels (used column levels + 1; or 0, if not used)
    width, height, row_level, col_level = work.unpack 'v4'
    worksheet.guts[:width] = width
    worksheet.guts[:height] = height
    worksheet.guts[:row_level] = row_level
    worksheet.guts[:col_level] = col_level
  end
  def read_style work, pos, len
    # User-Defined Cell Styles:
    # Offset  Size  Contents
    #      0     2  Bit   Mask    Contents
    #               11-0  0x0fff  Index to style XF record (➜ 6.115)
    #                 15  0x8000  Always 0 for user-defined styles
    #      2  var.  BIFF2-BIFF7:  Non-empty byte string,
    #                             8-bit string length (➜ 3.3)
    #               BIFF8:        Non-empty Unicode string,
    #                             16-bit string length (➜ 3.4)
    #
    # Built-In Cell Styles
    # Offset  Size  Contents
    #      0     2  Bit   Mask    Contents
    #               11-0  0x0FFF  Index to style XF record (➜ 6.115)
    #                 15  0x8000  Always 1 for built-in styles
    #      2     1  Identifier of the built-in cell style:
    #               0x00 = Normal
    #               0x01 = RowLevel_lv (see next field)
    #               0x02 = ColLevel_lv (see next field)
    #               0x03 = Comma
    #               0x04 = Currency
    #               0x05 = Percent
    #               0x06 = Comma [0] (BIFF4-BIFF8)
    #               0x07 = Currency [0] (BIFF4-BIFF8)
    #               0x08 = Hyperlink (BIFF8)
    #               0x09 = Followed Hyperlink (BIFF8)
    #      3     1  Level for RowLevel or ColLevel style (zero-based, lv),
    #               FFH otherwise
    flags, = work.unpack 'v'
    xf_idx = flags & 0x0fff
    xf = @workbook.format xf_idx
    builtin = flags & 0x8000
    if builtin == 0
      xf.name = client read_string(work[2..-1], 2), @workbook.encoding
    else
      id, level = work.unpack 'x2C2'
      if name = BUILTIN_STYLES[id]
        name.sub '_lv', "_#{level.to_s}"
        xf.name = client name, 'UTF-8'
      end
    end
  end
  def read_xf work, pos, len
    # Offset  Size  Contents
    #      0     2  Index to FONT record (➜ 6.43)
    #      2     2  Index to FORMAT record (➜ 6.45)
    #      4     2   Bit  Mask    Contents
    #                2-0  0x0007  XF_TYPE_PROT – XF type, cell protection
    #                             Bit  Mask  Contents
    #                               0  0x01  1 = Cell is locked
    #                               1  0x02  1 = Formula is hidden
    #                               2  0x04  0 = Cell XF; 1 = Style XF
    #               15-4  0xfff0  Index to parent style XF
    #                             (always 0xfff in style XFs)
    #      6     1   Bit  Mask    Contents
    #                2-0  0x07    XF_HOR_ALIGN – Horizontal alignment
    #                             Value  Horizontal alignment
    #                             0x00   General
    #                             0x01   Left
    #                             0x02   Centred
    #                             0x03   Right
    #                             0x04   Filled
    #                             0x05   Justified (BIFF4-BIFF8X)
    #                             0x06   Centred across selection
    #                                    (BIFF4-BIFF8X)
    #                             0x07   Distributed (BIFF8X)
    #                  3  0x08    1 = Text is wrapped at right border
    #                6-4  0x70    XF_VERT_ALIGN – Vertical alignment
    #                             Value  Vertical alignment
    #                             0x00   Top
    #                             0x01   Centred
    #                             0x02   Bottom
    #                             0x03   Justified (BIFF5-BIFF8X)
    #                             0x04   Distributed (BIFF8X)
    #      7     1  XF_ROTATION: Text rotation angle (see above)
    #                Value  Text rotation
    #                    0  Not rotated
    #                 1-90  1 to 90 degrees counterclockwise
    #               91-180  1 to 90 degrees clockwise
    #                  255  Letters are stacked top-to-bottom,
    #                       but not rotated
    #      8     1   Bit  Mask    Contents
    #                3-0  0x0f    Indent level
    #                  4  0x10    1 = Shrink content to fit into cell
    #                  5  0x40    1 = Merge Range (djberger)
    #                7-6  0xc0    Text direction (BIFF8X only)
    #                             0 = According to context
    #                             1 = Left-to-right
    #                             2 = Right-to-left
    #      9     1   Bit  Mask    Contents
    #                7-2  0xfc    XF_USED_ATTRIB – Used attributes
    #                             Each bit describes the validity of a
    #                             specific group of attributes. In cell XFs
    #                             a cleared bit means the attributes of the
    #                             parent style XF are used (but only if the
    #                             attributes are valid there), a set bit
    #                             means the attributes of this XF are used.
    #                             In style XFs a cleared bit means the
    #                             attribute setting is valid, a set bit
    #                             means the attribute should be ignored.
    #                             Bit  Mask  Contents
    #                               0  0x01  Flag for number format
    #                               1  0x02  Flag for font
    #                               2  0x04  Flag for horizontal and
    #                                        vertical alignment, text wrap,
    #                                        indentation, orientation,
    #                                        rotation, and text direction
    #                               3  0x08  Flag for border lines
    #                               4  0x10  Flag for background area style
    #                               5  0x20  Flag for cell protection (cell
    #                                        locked and formula hidden)
    #     10     4  Cell border lines and background area:
    #                 Bit  Mask        Contents
    #                3- 0  0x0000000f  Left line style (➜ 3.10)
    #                7- 4  0x000000f0  Right line style (➜ 3.10)
    #               11- 8  0x00000f00  Top line style (➜ 3.10)
    #               15-12  0x0000f000  Bottom line style (➜ 3.10)
    #               22-16  0x007f0000  Colour index (➜ 6.70)
    #                                  for left line colour
    #               29-23  0x3f800000  Colour index (➜ 6.70)
    #                                  for right line colour
    #                  30  0x40000000  1 = Diagonal line
    #                                  from top left to right bottom
    #                  31  0x80000000  1 = Diagonal line
    #                                  from bottom left to right top
    #     14     4    Bit  Mask        Contents
    #                6- 0  0x0000007f  Colour index (➜ 6.70)
    #                                  for top line colour
    #               13- 7  0x00003f80  Colour index (➜ 6.70)
    #                                  for bottom line colour
    #               20-14  0x001fc000  Colour index (➜ 6.70)
    #                                  for diagonal line colour
    #               24-21  0x01e00000  Diagonal line style (➜ 3.10)
    #               31-26  0xfc000000  Fill pattern (➜ 3.11)
    #     18     2    Bit  Mask        Contents
    #                 6-0  0x007f      Colour index (➜ 6.70)
    #                                  for pattern colour
    #                13-7  0x3f80      Colour index (➜ 6.70)
    #                                  for pattern background
    fmt = Format.new
    font_idx, numfmt, _, xf_align, xf_rotation, xf_indent, _,
      xf_borders, xf_brdcolors, xf_pattern = work.unpack binfmt(:xf)
    fmt.number_format = @formats[numfmt]
    ## this appears to be undocumented: the first 4 fonts seem to be accessed
    #  with a 0-based index, but all subsequent font indices are 1-based.
    fmt.font = @workbook.font(font_idx > 3 ? font_idx - 1 : font_idx)
    fmt.horizontal_align = NGILA_H_FX[xf_align & 0x07]
    fmt.text_wrap = xf_align & 0x08 > 0
    fmt.vertical_align = NGILA_V_FX[xf_align & 0x70]
    fmt.rotation = if xf_rotation == 255
                     :stacked
                   elsif xf_rotation > 90
                     90 - xf_rotation
                   else
                     xf_rotation
                   end
    fmt.indent_level = xf_indent & 0x0f
    fmt.shrink = xf_indent & 0x10 > 0
    fmt.text_direction = NOITCERID_TXET_FX[xf_indent & 0xc0]
    fmt.left           = XF_BORDER_LINE_STYLES[xf_borders & 0x0000000f]
    fmt.right          = XF_BORDER_LINE_STYLES[(xf_borders & 0x000000f0) >>  4]
    fmt.top            = XF_BORDER_LINE_STYLES[(xf_borders & 0x00000f00) >>  8]
    fmt.bottom         = XF_BORDER_LINE_STYLES[(xf_borders & 0x0000f000) >> 12]
    fmt.left_color     = COLOR_CODES[(xf_borders & 0x007f0000) >> 16] || :black
    fmt.right_color    = COLOR_CODES[(xf_borders & 0x3f800000) >> 23] || :black
    fmt.cross_down     = xf_borders & 0x40000000 > 0
    fmt.cross_up       = xf_borders & 0x80000000 > 0
		if xf_brdcolors
    	fmt.top_color      = COLOR_CODES[xf_brdcolors & 0x0000007f] || :black
    	fmt.bottom_color   = COLOR_CODES[(xf_brdcolors & 0x00003f80) >> 7] || :black
    	fmt.diagonal_color = COLOR_CODES[(xf_brdcolors & 0x001fc000) >> 14] || :black
    	#fmt.diagonal_style = COLOR_CODES[xf_brdcolors & 0x01e00000]
    	fmt.pattern        = (xf_brdcolors & 0xfc000000) >> 26
		end
    fmt.pattern_fg_color = COLOR_CODES[xf_pattern & 0x007f] || :border
    fmt.pattern_bg_color = COLOR_CODES[(xf_pattern & 0x3f80) >> 7] || :pattern_bg
    @workbook.add_format fmt
  end
  def read_note worksheet, work, pos, len
    #puts "\nDEBUG: found a note record in read_worksheet\n"
    row, col, _, _objID, _objAuthLen, _objAuthLenFmt = work.unpack('v5C')
    if (_objAuthLen > 0)
       if (_objAuthLenFmt == 0)
          #puts "Picking compressed charset"
          #Skip to offset due to 'v5C' used above
          _objAuth = work.unpack('@11C' + (_objAuthLen-1).to_s + 'C')
       elsif (_objAuthLenFmt == 1)
          #puts "Picking uncompressed charset"
          _objAuth = work.unpack('@11S' + (_objAuthLen-1).to_s + 'S')
       end
       _objAuth = _objAuth.pack('C*')
    else
       _objAuth = ""
    end
    @note = Note.new
    @note.length = len
    @note.row    = row
    @note.col    = col
    @note.author = _objAuth
    @note.objID  = _objID
    #Pop it on the list to be sorted in postread_worksheet
    @noteList << @note
  end
  def read_sheet_protection worksheet, op, data
    case op
    when :protect
      worksheet.protect! if data.unpack('v').first == 1
    when :password
      worksheet.password_hash = data.unpack('v').first
    end
  end
  def set_cell worksheet, row, column, xf, value=nil
    cells = @current_row_block[[worksheet, row]] ||= Row.new(nil, row)
    cells.formats[column] = @workbook.format(xf) unless xf == 0
    cells[column] = value
  end
  def set_missing_row_address worksheet, work, pos, len
    # Offset  Size  Contents
    #      0     2  Index of this row
    #      2     2  Index to this column
    row_index, _ = work.unpack 'v2'
    unless worksheet.offsets[row_index]
      @current_row_block_offset ||= [pos]
      data = {
        :index          => row_index,
        :row_block      => @current_row_block_offset,
        :offset         => @current_row_block_offset[0],
      }
      worksheet.set_row_address row_index, data
    end
  end
  def set_row_address worksheet, work, pos, len
    # Offset  Size  Contents
    #      0     2  Index of this row
    #      2     2  Index to column of the first cell which
    #               is described by a cell record
    #      4     2  Index to column of the last cell which is
    #               described by a cell record, increased by 1
    #      6     2  Bit   Mask    Contents
    #               14-0  0x7fff  Height of the row, in twips = 1/20 of a point
    #                 15  0x8000  0 = Row has custom height;
    #                             1 = Row has default height
    #      8     2  Not used
    #     10     2  In BIFF3-BIFF4 this field contains a relative offset to
    #               calculate stream position of the first cell record for this
    #               row (➜ 5.7.1). In BIFF5-BIFF8 this field is not used
    #               anymore, but the DBCELL record (➜ 6.26) instead.
    #     12     4  Option flags and default row formatting:
    #                  Bit  Mask        Contents
    #                  2-0  0x00000007  Outline level of the row
    #                    4  0x00000010  1 = Outline group starts or ends here
    #                                       (depending on where the outline
    #                                       buttons are located, see WSBOOL
    #                                       record, ➜ 6.113), and is collapsed
    #                    5  0x00000020  1 = Row is hidden (manually, or by a
    #                                       filter or outline group)
    #                    6  0x00000040  1 = Row height and default font height
    #                                       do not match
    #                    7  0x00000080  1 = Row has explicit default format (fl)
    #                    8  0x00000100  Always 1
    #                27-16  0x0fff0000  If fl = 1: Index to default XF record
    #                                              (➜ 6.115)
    #                   28  0x10000000  1 = Additional space above the row.
    #                                       This flag is set, if the upper
    #                                       border of at least one cell in this
    #                                       row or if the lower border of at
    #                                       least one cell in the row above is
    #                                       formatted with a thick line style.
    #                                       Thin and medium line styles are not
    #                                       taken into account.
    #                   29  0x20000000  1 = Additional space below the row.
    #                                       This flag is set, if the lower
    #                                       border of at least one cell in this
    #                                       row or if the upper border of at
    #                                       least one cell in the row below is
    #                                       formatted with a medium or thick
    #                                       line style. Thin line styles are
    #                                       not taken into account.
    @current_row_block_offset ||= [pos]
    index, first_used, first_unused, height, flags = work.unpack binfmt(:row)
    height &= 0x7fff
    format = nil
    # TODO: read attributes from work[13,3], read flags
    attrs = {
      :default_format => format,
      :first_used     => first_used,
      :first_unused   => first_unused,
      :index          => index,
      :row_block      => @current_row_block_offset,
      :offset         => @current_row_block_offset[0],
      :outline_level  => flags & 0x00000007,
      :collapsed      => (flags & 0x0000010) > 0,
      :hidden         => (flags & 0x0000020) > 0,
    }
    if (flags & 0x00000040) > 0
      attrs.store :height, height / TWIPS
    end
    if (flags & 0x00000080) > 0
      xf = (flags & 0x0fff0000) >> 16
      attrs.store :default_format, @workbook.format(xf)
    end
    # TODO: Row spacing
    worksheet.set_row_address index, attrs
  end
  def setup io
    ## Reading from StringIO fails without forced encoding
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.3.0')
      io.set_encoding('ASCII-8BIT')
    elsif io.respond_to?(:string) && (str = io.string) && str.respond_to?(:force_encoding)
      str.force_encoding('ASCII-8BIT')
    end
    io.rewind
    @ole = Ole::Storage.open io
    @workbook = Workbook.new io, {}
    %w{Book Workbook BOOK WORKBOOK book workbook}.any? do |name|
      @book = @ole.file.open(name) rescue false
    end
    raise RuntimeError, "could not locate a workbook, possibly an empty file passed" unless @book
    @data = @book.read
    read_bof
    @workbook.ole = @book
    @workbook.bof = @bof
    @workbook.version = @version
    biff = @workbook.biff_version
    extend_reader biff
    extend_internals biff
  end
  private
  def extend_internals version
    require 'spreadsheet/excel/internals/biff%i' % version
    extend Internals.const_get('Biff%i' % version)
    ## spreadsheets may not include a codepage record.
    @workbook.encoding = encoding 850 if version < 8
  rescue LoadError
  end
  def extend_reader version
    require 'spreadsheet/excel/reader/biff%i' % version
    extend Reader.const_get('Biff%i' % version)
  rescue LoadError
  end
end
  end
end

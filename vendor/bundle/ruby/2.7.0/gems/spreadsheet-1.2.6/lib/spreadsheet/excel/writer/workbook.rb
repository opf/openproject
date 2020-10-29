require 'spreadsheet/excel/internals'
require 'spreadsheet/writer'
require 'spreadsheet/excel/writer/biff8'
require 'spreadsheet/excel/writer/format'
require 'spreadsheet/excel/writer/worksheet'
require 'ole/storage'

module Spreadsheet
  module Excel
    module Writer
##
# Writer class for Excel Workbooks. Most write_* method correspond to an
# Excel-Record/Opcode. Designed to be able to write several Workbooks in
# parallel (just because I can't imagine why you would want to do that
# doesn't mean it shouldn't be possible ;). You should not need to call any of
# its methods directly. If you think you do, look at #write_workbook
class Workbook < Spreadsheet::Writer
  include Spreadsheet::Excel::Writer::Biff8
  include Spreadsheet::Excel::Internals
  attr_reader :fonts, :date_base
  def initialize *args
    super
    @biff_version = 0x0600
    @bof = 0x0809
    @build_id = 3515
    @build_year = 1996
    @bof_types = {
      :globals      => 0x0005,
      :visual_basic => 0x0006,
      :worksheet    => 0x0010,
      :chart        => 0x0020,
      :macro_sheet  => 0x0040,
      :workspace    => 0x0100,
    }
    @worksheets = {}
    @sst = {}
    @recordsize_limit = 8224
    @fonts = {}
    @formats = {}
    @number_formats = {}
  end
  def cleanup workbook
    worksheets(workbook).each do |worksheet|
      @sst.delete worksheet
    end
    @fonts.delete workbook
    @formats.delete workbook
    @number_formats.delete workbook
    @worksheets.delete workbook
  end
  def collect_formats workbook, opts={}
    # The default cell format is always present in an Excel file, described by
    # the XF record with the fixed index 15 (0-based). By default, it uses the
    # worksheet/workbook default cell style, described by the very first XF
    # record (index 0).
    formats = []
    unless opts[:existing_document]
      15.times do
        formats.push Format.new(self, workbook, workbook.default_format,
                                :type => :style)
      end
      formats.push Format.new(self, workbook)
    end
    workbook.formats.each do |fmt|
      formats.push Format.new(self, workbook, fmt)
    end
    @formats[workbook] = {
      :writers => [],
      :xf_indexes => {}
    }
    formats.each_with_index do |fmt, idx|
      @formats[workbook][:writers] << fmt
      @formats[workbook][:xf_indexes][fmt.format] ||= idx
    end
  end
  def complete_sst_update? workbook
    stored = workbook.sst.collect do |entry| entry.content end
    num_total = 0
    current = worksheets(workbook).inject(Hash.new(0)) do |memo, worksheet|
      worksheet.strings.each do |k,v|
        memo[k] += v
        num_total += v
      end
      memo
    end
    current.delete ''
    if !stored.empty? && stored.all?{|x| current.include?(x) }
      ## if all previously stored strings are still needed, we don't have to
      #  rewrite all cells because the sst-index of such string does not change.
      additions = current.keys - stored
      [:partial_update, num_total, stored + additions]
    else
      [:complete_update, num_total, current.keys]
    end
  end
  def font_index workbook, font_key
    idx = @fonts[workbook][font_key] || 0
    ## this appears to be undocumented: the first 4 fonts seem to be accessed
    #  with a 0-based index, but all subsequent font indices are 1-based.
    idx > 3 ? idx.next : idx
  end
  def number_format_index workbook, format
    @number_formats[workbook][format] || 0
  end
  def sanitize_worksheets sheets
    return sheets if sheets.empty?
    found_selected = false
    sheets.each do |sheet|
      found_selected ||= sheet.selected
      sheet.format_dates!
    end
    unless found_selected
      sheets.first.selected = true
    end
    sheets
  end
  def worksheets workbook
    @worksheets[workbook] ||= workbook.worksheets.collect do |worksheet|
      Excel::Writer::Worksheet.new self, worksheet
    end
  end
  def write_bof workbook, writer, type
    data = [
      @biff_version,    # BIFF version (always 0x0600 for BIFF8)
      @bof_types[type], # Type of the following data:
                        # 0x0005 = Workbook globals
                        # 0x0006 = Visual Basic module
                        # 0x0010 = Worksheet
                        # 0x0020 = Chart
                        # 0x0040 = Macro sheet
                        # 0x0100 = Workspace file
      @build_id,        # Build identifier
      @build_year,      # Build year
      0x000,            # File history flags
      0x006,            # Lowest Excel version that can read
                        # all records in this file
    ]
    write_op writer, @bof, data.pack("v4V2")
  end
  def write_bookbool workbook, writer
    write_placeholder writer, 0x00da
  end
  def write_boundsheets workbook, writer, offset
    worksheets = worksheets(workbook)
    worksheets.each do |worksheet|
      # account for boundsheet-entry
      offset += worksheet.boundsheet_size
    end
    worksheets.each do |worksheet|
      visibility = SEITILIBISIV_TEEHSKROW[worksheet.worksheet.visibility]
      data = [
        offset,   # Absolute stream position of the BOF record of the sheet
                  # represented by this record. This field is never encrypted
                  # in protected files.
        visibility,     # Visibility: 0x00 = Visible
                  #             0x01 = Hidden
                  #             0x02 = Strong hidden (see below)
        0x00,     # Sheet type: 0x00 = Worksheet
                  #             0x02 = Chart
                  #             0x06 = Visual Basic module
      ]
      write_op writer, 0x0085, data.pack("VC2"), worksheet.name
      offset += worksheet.size
    end
  end
  ##
  # Copy unchanged data verbatim, adjust offsets and write new records for
  # changed data.
  def write_changes workbook, io
    sanitize_worksheets workbook.worksheets
    collect_formats workbook, :existing_document => true
    reader = workbook.ole
    sheet_data = {}
    sst_status, sst_total, sst_strings = complete_sst_update? workbook
    sst = {}
    sst_strings.each_with_index do |str, idx| sst.store str, idx end
    sheets = worksheets(workbook)
    positions = []
    newsheets = []
    sheets.each do |sheet|
      @sst[sheet] = sst
      pos, len = workbook.offsets[sheet.worksheet]
      if pos
        positions.push pos
        sheet.write_changes reader, pos + len, sst_status
      else
        newsheets.push sheet
        sheet.write_from_scratch
      end
      sheet_data[sheet.worksheet] = sheet.data
    end
    Ole::Storage.open io do |ole|
      ole.file.open 'Workbook', 'w' do |writer|
        reader.seek lastpos = 0
        workbook.offsets.select do |key, pair|
          workbook.changes.include? key
        end.sort_by do |key, (pos, _)|
          pos
        end.each do |key, (pos, len)|
          data = reader.read(pos - lastpos)
          writer.write data
          case key
          when Spreadsheet::Worksheet
            writer.write sheet_data[key]
          when :boundsheets
            ## boundsheets are hard to calculate. The offset below is only
            #  correct if there are no more changes in the workbook globals
            #  string after this.
            oldoffset = positions.min - len
            lastpos = pos + len
            bytechange = 0
            buffer = StringIO.new ''.dup
            if tuple = workbook.offsets[:sst]
              write_sst_changes workbook, buffer, writer.pos,
                                sst_total, sst_strings
              pos, len = tuple
              if offset = workbook.offsets[:extsst]
                len += offset[1].to_i
              end
              bytechange = buffer.size - len
              write_boundsheets workbook, writer, oldoffset + bytechange
              reader.seek lastpos
              writer.write reader.read(pos - lastpos)
              buffer.rewind
              writer.write buffer.read
            elsif sst.empty? || workbook.biff_version < 8
              write_boundsheets workbook, writer, oldoffset + bytechange
            else
              write_sst workbook, buffer, writer.pos
              write_boundsheets workbook, writer, oldoffset + buffer.size
              pos = lastpos
              len = positions.min - lastpos
              if len > OPCODE_SIZE
                reader.seek pos
                writer.write reader.read(len - OPCODE_SIZE)
              end
              buffer.rewind
              writer.write buffer.read
              write_eof workbook, writer
            end
          else
            send "write_#{key}", workbook, writer
          end
          lastpos = [pos + len, reader.size - 1].min
          reader.seek lastpos
        end
        writer.write reader.read
        newsheets.each do |sheet|
          writer.write sheet.data
        end
      end
    end
  end
  def write_datemode workbook, writer
    mode = @date_base.year == 1899 ? 0x00 : 0x01
    data = [
      mode, # 0 = Base date is 1899-Dec-31
            #     (the cell value 1 represents 1900-Jan-01)
            # 1 = Base date is 1904-Jan-01
            #     (the cell value 1 represents 1904-Jan-02)
    ]
    write_op writer, 0x0022, data.pack('v')
  end
  def write_dsf workbook, writer
    data = [
      0x00, # 0 = Only the BIFF8 “Workbook” stream is present
            # 1 = Additional BIFF5/BIFF7 “Book” stream is in the file
    ]
    write_op writer, 0x0161, data.pack('v')
  end
  def write_encoding workbook, writer
    enc = workbook.encoding || 'UTF-16LE'
    if RUBY_VERSION >= '1.9' && enc.is_a?(Encoding)
      enc = enc.name.upcase
    end
    cp = SEGAPEDOC.fetch(enc) do
      raise Spreadsheet::Errors::UnknownCodepage, "Invalid or Unknown Codepage '#{enc}'"
    end
    write_op writer, 0x0042, [cp].pack('v')
  end
  def write_eof workbook, writer
    write_op writer, 0x000a
  end
  def write_extsst workbook, offsets, writer
    header = [SST_CHUNKSIZE].pack('v')
    data = offsets.collect do |pair| pair.push(0).pack('Vv2') end
    write_op writer, 0x00ff, header, data
  end
  def write_font workbook, writer, font
    # TODO: Colors/Palette index
    size      = font.size * TWIPS
    color     = SEDOC_ROLOC[font.color] || SEDOC_ROLOC[:text]
    weight    = FONT_WEIGHTS.fetch(font.weight, font.weight)
    weight    = [[weight, 1000].min, 100].max
    esc       = SEPYT_TNEMEPACSE.fetch(font.escapement, 0)
    underline = SEPYT_ENILREDNU.fetch(font.underline, 0)
    family    = SEILIMAF_TNOF.fetch(font.family, 0)
    encoding  = SGNIDOCNE_TNOF.fetch(font.encoding, 0)
    options   = 0
    options  |= 0x0001 if weight > 600
    options  |= 0x0002 if font.italic?
    options  |= 0x0004 if underline > 0
    options  |= 0x0008 if font.strikeout?
    options  |= 0x0010 if font.outline?
    options  |= 0x0020 if font.shadow?
    data = [
      size,     # Height of the font (in twips = 1/20 of a point)
      options,  # Option flags:
                # Bit  Mask    Contents
                #   0  0x0001  1 = Characters are bold (redundant, see below)
                #   1  0x0002  1 = Characters are italic
                #   2  0x0004  1 = Characters are underlined (redundant)
                #   3  0x0008  1 = Characters are struck out
                #   4  0x0010  1 = Characters are outlined (djberger)
                #   5  0x0020  1 = Characters are shadowed (djberger)
      color,    # Palette index (➜ 6.70)
      weight,   # Font weight (100-1000). Standard values are
                #      0x0190 (400) for normal text and
                #      0x02bc (700) for bold text.
      esc,      # Escapement type: 0x0000 = None
                #                  0x0001 = Superscript
                #                  0x0002 = Subscript
      underline,# Underline type:  0x00 = None
                #                  0x01 = Single
                #                  0x02 = Double
                #                  0x21 = Single accounting
                #                  0x22 = Double accounting
      family,   # Font family:     0x00 = None (unknown or don't care)
                #                  0x01 = Roman (variable width, serifed)
                #                  0x02 = Swiss (variable width, sans-serifed)
                #                  0x03 = Modern (fixed width,
                #                                 serifed or sans-serifed)
                #                  0x04 = Script (cursive)
                #                  0x05 = Decorative (specialised,
                #                                       e.g. Old English, Fraktur)
      encoding, # Character set: 0x00 =   0 = ANSI Latin
                #                0x01 =   1 = System default
                #                0x02 =   2 = Symbol
                #                0x4d =  77 = Apple Roman
                #                0x80 = 128 = ANSI Japanese Shift-JIS
                #                0x81 = 129 = ANSI Korean (Hangul)
                #                0x82 = 130 = ANSI Korean (Johab)
                #                0x86 = 134 = ANSI Chinese Simplified GBK
                #                0x88 = 136 = ANSI Chinese Traditional BIG5
                #                0xa1 = 161 = ANSI Greek
                #                0xa2 = 162 = ANSI Turkish
                #                0xa3 = 163 = ANSI Vietnamese
                #                0xb1 = 177 = ANSI Hebrew
                #                0xb2 = 178 = ANSI Arabic
                #                0xba = 186 = ANSI Baltic
                #                0xcc = 204 = ANSI Cyrillic
                #                0xde = 222 = ANSI Thai
                #                0xee = 238 = ANSI Latin II (Central European)
                #                0xff = 255 = OEM Latin I
    ]
    name = unicode_string font.name # Font name: Unicode string,
                                    # 8-bit string length (➜ 3.4)
    write_op writer, opcode(:font), data.pack(binfmt(:font)), name
  end
  def write_fonts workbook, writer
    fonts = @fonts[workbook] = {}
    @formats[workbook][:writers].map{|format| format.font }.compact.uniq.each do |font|
      unless fonts.include?(font.key)
        fonts.store font.key, fonts.size
        write_font workbook, writer, font
      end
    end
  end
  def write_formats workbook, writer
    # From BIFF5 on, the built-in number formats will be omitted. The built-in
    # formats are dependent on the current regional settings of the operating
    # system. BUILTIN_FORMATS shows which number formats are used by
    # default in a US-English environment. All indexes from 0 to 163 are
    # reserved for built-in formats.
    # The first user-defined format starts at 164 (0xa4).
    formats = @number_formats[workbook] = {}
    BUILTIN_FORMATS.each do |idx, str|
      formats.store client(str, 'UTF-8'), idx
    end
    ## Ensure at least a 'GENERAL' format is written
    formats.delete client('GENERAL', 'UTF-8')
    idx = 0xa4
    workbook.formats.each do |fmt|
      str = fmt.number_format
      unless formats[str]
        formats.store str, idx
        # Number format string (Unicode string, 16-bit string length, ➜ 3.4)
        write_op writer, opcode(:format), [idx].pack('v'), unicode_string(str, 2)
        idx += 1
      end
    end
  end
  ##
  # Write a new Excel file.
  def write_from_scratch workbook, io
    sanitize_worksheets workbook.worksheets
    collect_formats workbook
    sheets = worksheets workbook
    buffer1 = StringIO.new ''.dup
    # ●  BOF Type = workbook globals (➜ 6.8)
    write_bof workbook, buffer1, :globals
    # ○  File Protection Block ➜ 4.19
    # ○  WRITEACCESS User name (BIFF3-BIFF8, ➜ 5.112)
    # ○  FILESHARING File sharing options (BIFF3-BIFF8, ➜ 5.44)
    # ○  CODEPAGE ➜ 6.17
    write_encoding workbook, buffer1
    # ○  DSF ➜ 6.32
    write_dsf workbook, buffer1
    # ○  TABID
    write_tabid workbook, buffer1
    # ○  FNGROUPCOUNT
    # ○  Workbook Protection Block ➜ 4.18
    # ○  WINDOWPROTECT Window settings: 1 = protected (➜ 5.111)
    # ○  PROTECT Cell contents: 1 = protected (➜ 5.82)
    write_protect workbook, buffer1
    # ○  OBJECTPROTECT Embedded objects: 1 = protected (➜ 5.72)
    # ○  PASSWORD Hash value of the password; 0 = No password (➜ 5.76)
    write_password workbook, buffer1
    # ○  BACKUP ➜ 5.5
    # ○  HIDEOBJ ➜ 5.56
    # ●  WINDOW1 ➜ 5.109
    write_window1 workbook, buffer1
    # ○  DATEMODE ➜ 5.28
    write_datemode workbook, buffer1
    # ○  PRECISION ➜ 5.79
    write_precision workbook, buffer1
    # ○  REFRESHALL
    write_refreshall workbook, buffer1
    # ○  BOOKBOOL ➜ 5.9
    write_bookbool workbook, buffer1
    # ●● FONT ➜ 5.45
    write_fonts workbook, buffer1
    # ○○ FORMAT ➜ 5.49
    write_formats workbook, buffer1
    # ●● XF ➜ 5.115
    write_xfs workbook, buffer1
    # ●● STYLE ➜ 5.103
    write_styles workbook, buffer1
    # ○  PALETTE ➜ 5.74
    write_palette workbook, buffer1
    # ○  USESELFS ➜ 5.106
    buffer1.rewind
    # ●● BOUNDSHEET ➜ 5.95
    buffer2 = StringIO.new ''.dup
    # ○  COUNTRY ➜ 5.22
    # ○  Link Table ➜ 4.10.3
    # ○○ NAME ➜ 6.66
    # ○  Shared String Table ➜ 4.11
    # ●  SST ➜ 5.100
    # ●  EXTSST ➜ 5.42
    write_sst workbook, buffer2, buffer1.size
    # ●  EOF ➜ 5.37
    write_eof workbook, buffer2
    buffer2.rewind
    # worksheet data can only be assembled after write_sst
    sheets.each do |worksheet| worksheet.write_from_scratch end
    Ole::Storage.open io do |ole|
      ole.file.open 'Workbook', 'w' do |writer|
        writer.write buffer1.read
        write_boundsheets workbook, writer, buffer1.size + buffer2.size
        writer.write buffer2.read
        sheets.each do |worksheet|
          writer.write worksheet.data
        end
      end
    end
  end
  def write_op writer, op, *args
    data = args.join
    limited = data.slice!(0...@recordsize_limit)
    writer.write [op,limited.size].pack("v2")
    writer.write limited
    data
  end
  def write_password workbook, writer
    write_placeholder writer, 0x0013
  end
  def write_placeholder writer, op, value=0x0000, fmt='v'
    write_op writer, op, [value].pack(fmt)
  end
  def write_precision workbook, writer
    # 0 = Use displayed values; 1 = Use real cell values
    write_placeholder writer, 0x000e, 0x0001
  end
  def write_protect workbook, writer
    write_placeholder writer, 0x0012
  end
  def write_refreshall workbook, writer
    write_placeholder writer, 0x01b7
  end
  def write_sst workbook, writer, offset
    # Offset  Size  Contents
    #      0     4  Total number of strings in the workbook (see below)
    #      4     4  Number of following strings (nm)
    #      8  var.  List of nm Unicode strings, 16-bit string length (➜ 3.4)
    num_total = 0
    strings = worksheets(workbook).inject(Hash.new(0)) do |memo, worksheet|
      worksheet.strings.each do |k,v|
        memo[k] += v
        num_total += v
      end
      memo
    end
    _write_sst workbook, writer, offset, num_total, strings.keys
  end
  def _write_sst workbook, writer, offset, total, strings
    sst = {}
    worksheets(workbook).each do |worksheet|
      offset += worksheet.boundsheet_size
      @sst[worksheet] = sst
    end
    sst_size = strings.size
    data = [total, sst_size].pack 'V2'
    op = 0x00fc
    wide = 0
    offsets = []
    strings.each_with_index do |string, idx|
      sst.store string, idx
      op_offset = data.size + 4
      if idx % SST_CHUNKSIZE == 0
        offsets.push [offset + writer.pos + op_offset, op_offset]
      end
      header, packed, next_wide = _unicode_string string, 2
      # the first few bytes (header + first character) must not be split
      must_fit = header.size + wide + 1
      while data.size + must_fit > @recordsize_limit
        op, data, wide = write_string_part writer, op, data, wide
      end
      wide = next_wide
      data << header << packed
    end
    until data.empty?
      op, data, wide = write_string_part writer, op, data, wide
    end
    write_extsst workbook, offsets, writer
  end
  def write_sst_changes workbook, writer, offset, total, strings
    _write_sst workbook, writer, offset, total, strings
  end
  def write_string_part writer, op, data, wide
    bef = data.size
    ## if we're writing wide characters, we need to make sure we don't cut
    #  characters in half
    if wide > 0 && data.size > @recordsize_limit
      remove = @recordsize_limit - bef
      remove -= remove % 2
      rest = data.slice!(remove..-1)
      write_op writer, op, data
      data = rest
    else
      data = write_op writer, op, data
    end
    op = 0x003c
    # Unicode strings are split in a special way. At the beginning of each
    # CONTINUE record the option flags byte is repeated. Only the
    # character size flag will be set in this flags byte, the Rich-Text
    # flag and the Far-East flag are set to zero.
    unless data.empty?
      if wide == 1
        # check if we can compress the rest of the string
        data, wide = compress_unicode_string data
      end
      data = [wide].pack('C') << data
    end
    [op, data, wide]
  end
  def write_styles workbook, writer
    # TODO: Style implementation. The following is simply a standard builtin
    #       style.
    # TODO: User defined styles
    data = [
      0x8000, #   Bit  Mask    Contents
              # 11- 0  0x0fff  Index to style XF record (➜ 6.115)
              #    15  0x8000  Always 1 for built-in styles
      0x00,   # Identifier of the built-in cell style:
              # 0x00 = Normal
              # 0x01 = RowLevel_lv (see next field)
              # 0x02 = ColLevel_lv (see next field)
              # 0x03 = Comma
              # 0x04 = Currency
              # 0x05 = Percent
              # 0x06 = Comma [0] (BIFF4-BIFF8)
              # 0x07 = Currency [0] (BIFF4-BIFF8)
              # 0x08 = Hyperlink (BIFF8)
              # 0x09 = Followed Hyperlink (BIFF8)
      0xff,   # Level for RowLevel or ColLevel style (zero-based, lv),
              # 0xff otherwise
              # The RowLevel and ColLevel styles specify the formatting of
              # subtotal cells in a specific outline level. The level is
              # specified by the last field in the STYLE record. Valid values
              # are 0…6 for the outline levels 1…7.
    ]
    write_op writer, 0x0293, data.pack('vC2')
  end
  def write_palette workbook, writer
    data = default_palette

    workbook.palette.each do |idx, color|
      idx = SEDOC_ROLOC[idx] - 8 if idx.kind_of? Symbol
      raise "Undefined color index: #{idx}" unless data[idx]
      data[idx] = color
    end

    writer.write [opcode(:palette), 2 + 4 * data.size, data.size].pack('v3')
    writer.write data.collect { |c| c.push(0).pack('C4') }.join
  end
  def write_tabid workbook, writer
    write_op writer, 0x013d, [1].pack('v')
  end
  def write_window1 workbook, writer
    selected = workbook.worksheets.find do |sheet| sheet.selected end
    actidx = workbook.worksheets.index selected
    data = [
      0x0000, # Horizontal position of the document window
              # (in twips = 1/20 of a point)
      0x0000, # Vertical position of the document window
              # (in twips = 1/20 of a point)
      0x4000, # Width of the document window (in twips = 1/20 of a point)
      0x2000, # Height of the document window (in twips = 1/20 of a point)
      0x0038, # Option flags:
              # Bit  Mask    Contents
              #   0  0x0001  0 = Window is visible
              #              1 = Window is hidden
              #   1  0x0002  0 = Window is open
              #              1 = Window is minimised
              #   3  0x0008  0 = Horizontal scroll bar hidden
              #              1 = Horizontal scroll bar visible
              #   4  0x0010  0 = Vertical scroll bar hidden
              #              1 = Vertical scroll bar visible
              #   5  0x0020  0 = Worksheet tab bar hidden
              #              1 = Worksheet tab bar visible
      actidx, # Index to active (displayed) worksheet
      0x0000, # Index of first visible tab in the worksheet tab bar
      0x0001, # Number of selected worksheets
              # (highlighted in the worksheet tab bar)
      0x00e5, # Width of worksheet tab bar (in 1/1000 of window width).
              # The remaining space is used by the horizontal scrollbar.
    ]
    write_op writer, 0x003d, data.pack('v*')
  end
  ##
  # The main writer method. Calls #write_from_scratch or #write_changes
  # depending on the class and state of _workbook_.
  def write_workbook workbook, io
    unless workbook.is_a?(Excel::Workbook) && workbook.io
      @date_base = Date.new 1899, 12, 31
      write_from_scratch workbook, io
    else
      @date_base = workbook.date_base
      if workbook.changes.empty?
        super
      else
        write_changes workbook, io
      end
    end
  ensure
    cleanup workbook
  end
  def write_xfs workbook, writer
    # The default cell format is always present in an Excel file, described by
    # the XF record with the fixed index 15 (0-based). By default, it uses the
    # worksheet/workbook default cell style, described by the very first XF
    # record (index 0).
    @formats[workbook][:writers].each do |fmt| fmt.write_xf writer end
  end
  def sst_index worksheet, str
    @sst[worksheet][str]
  end
  def xf_index workbook, format
    @formats[workbook][:xf_indexes][format] || 0
  end
  ##
  # Returns Excel 97+ default colour palette.
  def default_palette
    [
      [0x00, 0x00, 0x00],
      [0xff, 0xff, 0xff],
      [0xff, 0x00, 0x00],
      [0x00, 0xff, 0x00],
      [0x00, 0x00, 0xff],
      [0xff, 0xff, 0x00],
      [0xff, 0x00, 0xff],
      [0x00, 0xff, 0xff],
      [0x80, 0x00, 0x00],
      [0x00, 0x80, 0x00],
      [0x00, 0x00, 0x80],
      [0x80, 0x80, 0x00],
      [0x80, 0x00, 0x80],
      [0x00, 0x80, 0x80],
      [0xc0, 0xc0, 0xc0],
      [0x80, 0x80, 0x80],
      [0x99, 0x99, 0xff],
      [0x99, 0x33, 0x66],
      [0xff, 0xff, 0xcc],
      [0xcc, 0xff, 0xff],
      [0x66, 0x00, 0x66],
      [0xff, 0x80, 0x80],
      [0x00, 0x66, 0xcc],
      [0xcc, 0xcc, 0xff],
      [0x00, 0x00, 0x80],
      [0xff, 0x00, 0xff],
      [0xff, 0xff, 0x00],
      [0x00, 0xff, 0xff],
      [0x80, 0x00, 0x80],
      [0x80, 0x00, 0x00],
      [0x00, 0x80, 0x80],
      [0x00, 0x00, 0xff],
      [0x00, 0xcc, 0xff],
      [0xcc, 0xff, 0xff],
      [0xcc, 0xff, 0xcc],
      [0xff, 0xff, 0x99],
      [0x99, 0xcc, 0xff],
      [0xff, 0x99, 0xcc],
      [0xcc, 0x99, 0xff],
      [0xff, 0xcc, 0x99],
      [0x33, 0x66, 0xff],
      [0x33, 0xcc, 0xcc],
      [0x99, 0xcc, 0x00],
      [0xff, 0xcc, 0x00],
      [0xff, 0x99, 0x00],
      [0xff, 0x66, 0x00],
      [0x66, 0x66, 0x99],
      [0x96, 0x96, 0x96],
      [0x00, 0x33, 0x66],
      [0x33, 0x99, 0x66],
      [0x00, 0x33, 0x00],
      [0x33, 0x33, 0x00],
      [0x99, 0x33, 0x00],
      [0x99, 0x33, 0x66],
      [0x33, 0x33, 0x99],
      [0x33, 0x33, 0x33]
    ]
  end
end
    end
  end
end

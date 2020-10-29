require 'stringio'
require 'spreadsheet/excel/writer/biff8'
require 'spreadsheet/excel/internals'
require 'spreadsheet/excel/internals/biff8'

module Spreadsheet
  module Excel
    module Writer
##
# Writer class for Excel Worksheets. Most write_* method correspond to an
# Excel-Record/Opcode. You should not need to call any of its methods directly.
# If you think you do, look at #write_worksheet
class Worksheet
  include Spreadsheet::Excel::Writer::Biff8
  include Spreadsheet::Excel::Internals
  include Spreadsheet::Excel::Internals::Biff8
  attr_reader :worksheet
  def initialize workbook, worksheet
    @workbook = workbook
    @worksheet = worksheet
    @io = StringIO.new ''
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
  end
  ##
  # The number of bytes needed to write a Boundsheet record for this Worksheet
  # Used by Writer::Worksheet to calculate various offsets.
  def boundsheet_size
    name.size + 10
  end
  def data
    @io.rewind
    @io.read
  end
  def encode_date date
    return date if date.is_a? Numeric
    if date.is_a? Time
      date = DateTime.new date.year, date.month, date.day,
                          date.hour, date.min, date.sec
    end
    base = @workbook.date_base
    value = date - base
    if LEAP_ERROR > base
      value += 1
    end
    value
  end
  def encode_rk value
    #  Bit  Mask        Contents
    #    0  0x00000001  0 = Value not changed 1 = Value is multiplied by 100
    #    1  0x00000002  0 = Floating-point value 1 = Signed integer value
    # 31-2  0xFFFFFFFC  Encoded value
    cent = 0
    int = 2
    higher = value * 100
    if higher.is_a?(Float) && higher < 0xfffffffc
      cent = 1
      if higher == higher.to_i
        value = higher.to_i
      else
        value = higher
      end
    end
    if value.is_a?(Integer)
      ## although not documented as signed, 'V' appears to correctly pack
      #  negative numbers.
      value <<= 2
    else
      # FIXME: precision of small numbers
      int = 0
      value, = [value].pack(EIGHT_BYTE_DOUBLE).unpack('x4V')
      value &= 0xfffffffc
    end
    value | cent | int
  end
  def name
    unicode_string @worksheet.name
  end
  def need_number? cell
    if cell.is_a?(Numeric) && cell.abs > 0x1fffffff
      true
    elsif cell.is_a?(Float) and not cell.nan?
      higher = cell * 100
      if higher == higher.to_i
        need_number? higher.to_i
      else
        test1, test2 = [cell * 100].pack(EIGHT_BYTE_DOUBLE).unpack('V2')
        test1 > 0 || need_number?(test2)
      end
    else
      false
    end
  end
  def row_blocks
    # All cells in an Excel document are divided into blocks of 32 consecutive
    # rows, called Row Blocks. The first Row Block starts with the first used
    # row in that sheet. Inside each Row Block there will occur ROW records
    # describing the properties of the rows, and cell records with all the cell
    # contents in this Row Block.
    blocks = []
    @worksheet.reject do |row| row.empty? end.each_with_index do |row, idx|
      blocks << [] if idx % 32 == 0
      blocks.last << row
    end
    blocks
  end
  def size
    @io.size
  end
  def strings
    @worksheet.inject(Hash.new(0)) do |memo, row|
      row.each do |cell|
        memo[cell] += 1 if (cell.is_a?(String) && !cell.empty?)
      end
      memo
    end
  end
  ##
  # Write a blank cell
  def write_blank row, idx
    write_cell :blank, row, idx
  end
  def write_bof
    data = [
      @biff_version, # BIFF version (always 0x0600 for BIFF8)
      0x0010,        # Type of the following data:
                     # 0x0005 = Workbook globals
                     # 0x0006 = Visual Basic module
                     # 0x0010 = Worksheet
                     # 0x0020 = Chart
                     # 0x0040 = Macro sheet
                     # 0x0100 = Workspace file
      @build_id,     # Build identifier
      @build_year,   # Build year
      0x000,         # File history flags
      0x006,         # Lowest Excel version that can read
                     # all records in this file
    ]
    write_op @bof, data.pack("v4V2")
  end
  ##
  # Write a cell with a Boolean or Error value
  def write_boolerr row, idx
    value = row[idx]
    type = 0
    numval = 0
    if value.is_a? Error
      type = 1
      numval = value.code
    elsif value
      numval = 1
    end
    data = [
      numval, # Boolean or error value (type depends on the following byte)
      type    # 0 = Boolean value; 1 = Error code
    ]
    write_cell :boolerr, row, idx, *data
  end
  def write_calccount
    count = 100 # Maximum number of iterations allowed in circular references
    write_op 0x000c, [count].pack('v')
  end
  def write_cell type, row, idx, *args
    xf_idx = @workbook.xf_index @worksheet.workbook, row.format(idx)
    data = [
      row.idx, # Index to row
      idx,     # Index to column
      xf_idx,  # Index to XF record (➜ 6.115)
    ].concat args
    write_op opcode(type), data.pack(binfmt(type))
  end
  def write_cellblocks row
    # BLANK ➜ 6.7
    # BOOLERR ➜ 6.10
    # INTEGER ➜ 6.56 (BIFF2 only)
    # LABEL ➜ 6.59 (BIFF2-BIFF7)
    # LABELSST ➜ 6.61 (BIFF8 only)
    # MULBLANK ➜ 6.64 (BIFF5-BIFF8)
    # MULRK ➜ 6.65 (BIFF5-BIFF8)
    # NUMBER ➜ 6.68
    # RK ➜ 6.82 (BIFF3-BIFF8)
    # RSTRING ➜ 6.84 (BIFF5/BIFF7)
    multiples, first_idx = nil
    row = row.formatted
    row.each_with_index do |cell, idx|
      cell = nil if cell == ''
      ## it appears that there are limitations to RK precision, both for
      #  Integers and Floats, that lie well below 2^30 significant bits, or
      #  Ruby's Bignum threshold. In that case we'll just write a Number
      #  record
      need_number = need_number? cell
      if multiples && (!multiples.last.is_a?(cell.class) || need_number)
        write_multiples row, first_idx, multiples
        multiples, first_idx = nil
      end
      nxt = idx + 1
      case cell
      when NilClass
        if multiples
          multiples.push cell
        elsif nxt < row.size && row[nxt].nil?
          multiples = [cell]
          first_idx = idx
        else
          write_blank row, idx
        end
      when TrueClass, FalseClass, Error
        write_boolerr row, idx
      when String
        write_labelsst row, idx
      when Numeric
        ## RK encodes Floats with 30 significant bits, which is a bit more than
        #  10^9. Not sure what is a good rule of thumb here, but it seems that
        #  Decimal Numbers with more than 4 significant digits are not represented
        #  with sufficient precision by RK
        if need_number
          write_number row, idx
        elsif multiples
          multiples.push cell
        elsif nxt < row.size && row[nxt].is_a?(Numeric)
          multiples = [cell]
          first_idx = idx
        else
          write_rk row, idx
        end
      when Formula
        write_formula row, idx
      when Date, Time
        write_number row, idx
      end
    end
    write_multiples row, first_idx, multiples if multiples
  end
  def write_changes reader, endpos, sst_status

    ## FIXME this is not smart solution to update outline_level.
    #        without this process, outlines in row disappear in MS Excel.       
    @worksheet.row_count.times do |i|
      if @worksheet.row(i).outline_level > 0
        @worksheet.row(i).outline_level = @worksheet.row(i).outline_level
      end
    end

    reader.seek @worksheet.offset
    blocks = row_blocks
    lastpos = reader.pos
    offsets = {}
    row_offsets = []
    changes = @worksheet.changes
    @worksheet.offsets.each do |key, pair|
      if changes.include?(key) \
        || (sst_status == :complete_update && key.is_a?(Integer))
        offsets.store pair, key
      end
    end
    ## FIXME it may be smarter to simply write all rowblocks, instead of doing a
    #        song-and-dance routine for every row...
    work = offsets.invert
    work.each do |key, (pos, len)|
      case key
      when Integer
        row_offsets.push [key, [pos, len]]
      when :dimensions
        row_offsets.push [-1, [pos, len]]
      end
    end
    row_offsets.sort!
    row_offsets.reverse!
    control = changes.size
    @worksheet.each do |row|
      key = row.idx
      if changes.include?(key) && !work.include?(key)
        row, pair = row_offsets.find do |idx, _| idx <= key end
        work.store key, pair
      end
    end
    if changes.size > control
      warn <<-EOS
Your Worksheet was modified while it was being written. This should not happen.
Please contact the author (hannes dot wyss at gmail dot com) with a sample file
and minimal code that generates this warning. Thanks!
      EOS
    end
    work = work.sort_by do |key, (pos, len)|
      [pos, key.is_a?(Integer) ? key : -1]
    end
    work.each do |key, (pos, len)|
      @io.write reader.read(pos - lastpos) if pos > lastpos
      if key.is_a?(Integer)
        if block = blocks.find do |rows| rows.any? do |row| row.idx == key end end
          write_rowblock block
          blocks.delete block
        end
      else
        send "write_#{key}"
      end
      lastpos = pos + len
      reader.seek lastpos
    end

    # Necessary for outline (grouping) and hiding functions 
    # but these below are not necessary to run
    # if [Row|Column]#hidden? = false and [Row|Column]#outline_level == 0
    write_colinfos
    write_guts

    @io.write reader.read(endpos - lastpos)
  end
  def write_colinfo bunch
    col = bunch.first
    width = col.width.to_f * 256
    xf_idx = @workbook.xf_index @worksheet.workbook, col.default_format
    opts =  0
    opts |= 0x0001 if col.hidden?
    opts |= col.outline_level.to_i << 8
    opts |= 0x1000 if col.collapsed?
    data = [
      col.idx,        # Index to first column in the range
      bunch.last.idx, # Index to last column in the range
      width.to_i,     # Width of the columns in 1/256 of the width of the zero
                      # character, using default font (first FONT record in the
                      # file)
      xf_idx.to_i,    # Index to XF record (➜ 6.115) for default column formatting
      opts,           # Option flags:
                      # Bits  Mask    Contents
                      #    0  0x0001  1 = Columns are hidden
                      # 10-8  0x0700  Outline level of the columns
                      #               (0 = no outline)
                      #   12  0x1000  1 = Columns are collapsed
    ]
    write_op opcode(:colinfo), data.pack(binfmt(:colinfo))
  end
  def write_colinfos
    cols = @worksheet.columns
    bunch = []
    cols.each_with_index do |column, idx|
      if column
        bunch << column
        if cols[idx.next] != column
          write_colinfo bunch
          bunch.clear
        end
      end
    end
  end
  def write_defaultrowheight
    data = [
      0x00, # Option flags:
            # Bit  Mask  Contents
            #   0  0x01  1 = Row height and default font height do not match
            #   1  0x02  1 = Row is hidden
            #   2  0x04  1 = Additional space above the row
            #   3  0x08  1 = Additional space below the row
      0xf2, #   Default height for unused rows, in twips = 1/20 of a point
    ]
    write_op 0x0225, data.pack('v2')
  end
  def write_defcolwidth
    # Offset  Size  Contents
    #      0     2  Column width in characters, using the width of the zero
    #               character from default font (first FONT record in the
    #               file). Excel adds some extra space to the default width,
    #               depending on the default font and default font size. The
    #               algorithm how to exactly calculate the resulting column
    #               width is not known.
    #
    #               Example: The default width of 8 set in this record results
    #               in a column width of 8.43 using Arial font with a size of
    #               10 points.
    write_op 0x0055, [8].pack('v')
  end
  def write_dimensions
    # Offset  Size  Contents
    #      0     4  Index to first used row
    #      4     4  Index to last used row, increased by 1
    #      8     2  Index to first used column
    #     10     2  Index to last used column, increased by 1
    #     12     2  Not used
    write_op 0x0200, @worksheet.dimensions.pack(binfmt(:dimensions))
  end
  def write_eof
    write_op 0x000a
  end
  ##
  # Write a cell with a Formula. May write an additional String record depending
  # on the stored result of the Formula.
  def write_formula row, idx
    xf_idx = @workbook.xf_index @worksheet.workbook, row.format(idx)
    cell = row[idx]
    data1 = [
      row.idx,      # Index to row
      idx,          # Index to column
      xf_idx,       # Index to XF record (➜ 6.115)
    ].pack 'v3'
    data2 = nil
    case value = cell.value
    when Numeric    # IEEE 754 floating-point value (64-bit double precision)
      data2 = [value].pack EIGHT_BYTE_DOUBLE
    when String
      data2 = [
        0x00,       # (identifier for a string value)
        0xffff,     #
      ].pack 'Cx5v'
    when true, false
      value = value ? 1 : 0
      data2 = [
        0x01,     # (identifier for a Boolean value)
        value,    # 0 = FALSE, 1 = TRUE
        0xffff,   #
      ].pack 'CxCx3v'
    when Error
      data2 = [
        0x02,       # (identifier for an error value)
        value.code, # Error code
        0xffff,     #
      ].pack 'CxCx3v'
    when nil
      data2 = [
        0x03,       # (identifier for an empty cell)
        0xffff,     #
      ].pack 'Cx5v'
    else
      data2 = [
        0x02,       # (identifier for an error value)
        0x2a,       # Error code: #N/A! Argument or function not available
        0xffff,     #
      ].pack 'CxCx3v'
    end
    opts = 0x03
    opts |= 0x08 if cell.shared
    data3 = [
      opts        # Option flags:
                  # Bit  Mask    Contents
                  #   0  0x0001  1 = Recalculate always
                  #   1  0x0002  1 = Calculate on open
                  #   3  0x0008  1 = Part of a shared formula
    ].pack 'vx4'
    write_op opcode(:formula), data1, data2, data3, cell.data
    if cell.value.is_a?(String)
      write_op opcode(:string), unicode_string(cell.value, 2)
    end
  end
  ##
  # Write a new Worksheet.
  def write_from_scratch
    # ●  BOF Type = worksheet (➜ 5.8)
    write_bof
    # ○  UNCALCED ➜ 5.105
    # ○  INDEX ➜ 4.7 (Row Blocks), ➜ 5.59
    # ○  Calculation Settings Block ➜ 4.3
    write_calccount
    write_refmode
    write_iteration
    write_saverecalc
    # ○  PRINTHEADERS ➜ 5.81
    # ○  PRINTGRIDLINES ➜ 5.80
    # ○  GRIDSET ➜ 5.52
    # ○  GUTS ➜ 5.53
    write_guts
    # ○  DEFAULTROWHEIGHT ➜ 5.31
    write_defaultrowheight
    # ○  WSBOOL ➜ 5.113
    write_wsbool
    # ○  Page Settings Block ➜ 4.4
    # ○  Worksheet Protection Block ➜ 4.18
    # ○  DEFCOLWIDTH ➜ 5.32
    write_defcolwidth
    # ○○ COLINFO ➜ 5.18
    write_colinfos
    # ○  SORT ➜ 5.99
    # ●  DIMENSIONS ➜ 5.35
    write_dimensions
    # ○○ Row Blocks ➜ 4.7
    write_rows
    # ●  Worksheet View Settings Block ➜ 4.5
    # ●  WINDOW2 ➜ 5.110
    write_window2
    # ○  SCL ➜ 5.92 (BIFF4-BIFF8 only)
    # ○  PANE ➜ 5.75
    # ○○ SELECTION ➜ 5.93
    # ○  STANDARDWIDTH ➜ 5.101
    # ○○ MERGEDCELLS ➜ 5.67
    # ○  LABELRANGES ➜ 5.64
    # ○  PHONETIC ➜ 5.77
    # ○  Conditional Formatting Table ➜ 4.12
    # ○  Hyperlink Table ➜ 4.13
    write_hyperlink_table
    # ○  Data Validity Table ➜ 4.14
    # ○  SHEETLAYOUT ➜ 5.96 (BIFF8X only)
    # ○  SHEETPROTECTION Additional protection, ➜ 5.98 (BIFF8X only)
    # ○  RANGEPROTECTION Additional protection, ➜ 5.84 (BIFF8X only)
    # ●  EOF ➜ 5.36
    write_eof
  end
  ##
  # Write record that contains information about the layout of outline symbols.
  def write_guts
    # find the maximum outline_level in rows and columns
    row_outline_level = 0
    col_outline_level = 0
    if(row = @worksheet.rows.select{|x| x!=nil}.max{|a,b| a.outline_level <=> b.outline_level})
      row_outline_level = row.outline_level
    end
    if(col = @worksheet.columns.select{|x| x!=nil}.max{|a,b| a.outline_level <=> b.outline_level})
      col_outline_level = col.outline_level
    end
    # set data
    data = [
      0,  # Width of the area to display row outlines (left of the sheet), in pixel
      0,  # Height of the area to display column outlines (above the sheet), in pixel
      row_outline_level+1, # Number of visible row outline levels (used row levels+1; or 0,if not used)
      col_outline_level+1  # Number of visible column outline levels (used column levels+1; or 0,if not used)
    ]
    # write record
    write_op opcode(:guts), data.pack('v4')
  end
  def write_hlink row, col, link
    # FIXME: only Hyperlinks are supported at present.
    cell_range = [
      row, row, # Cell range address of all cells containing this hyperlink
      col, col, # (➜ 3.13.1)
    ].pack 'v4'
    guid = [
      # GUID of StdLink:
      # D0 C9 EA 79 F9 BA CE 11 8C 82 00 AA 00 4B A9 0B
      # (79EAC9D0-BAF9-11CE-8C82-00AA004BA90B)
      "d0c9ea79f9bace118c8200aa004ba90b",
    ].pack 'H32'
    opts  = 0x01
    opts |= 0x02
    opts |= 0x14 unless link == link.url
    opts |= 0x08 if link.fragment
    opts |= 0x80 if link.target_frame
    # TODO: UNC support
    options = [
      2,        # Unknown value: 0x00000002
      opts,     # Option flags
                #     Bit  Mask        Contents
                #       0  0x00000001  0 = No link extant
                #                      1 = File link or URL
                #       1  0x00000002  0 = Relative file path
                #                      1 = Absolute path or URL
                # 2 and 4  0x00000014  0 = No description
                #                      1 (both bits) = Description
                #       3  0x00000008  0 = No text mark
                #                      1 = Text mark
                #       7  0x00000080  0 = No target frame
                #                      1 = Target frame
                #       8  0x00000100  0 = File link or URL
                #                      1 = UNC path (incl. server name)

    ].pack('V2')
    tail = []
    ## call internal to get the correct internal encoding in Ruby 1.9
    nullstr = internal "\000"
    unless link == link.url
      desc = internal(link).dup << nullstr
      tail.push [desc.size / 2].pack('V'), desc
    end
    if link.target_frame
      frme = internal(link.target_frame).dup << nullstr
      tail.push [frme.size / 2].pack('V'), frme
    end
    url = internal(link.url).dup << nullstr
    tail.push [
      # 6.53.2 Hyperlink containing a URL (Uniform Resource Locator)
      # These data fields occur for links which are not local files or files
      # in the local network (for instance HTTP and FTP links and e-mail
      # addresses). The lower 9 bits of the option flags field must be
      # 0.x00x.xx112 (x means optional, depending on hyperlink content). The
      # GUID could be used to distinguish a URL from a file link.
      # GUID of URL Moniker:
      # E0 C9 EA 79 F9 BA CE 11 8C 82 00 AA 00 4B A9 0B
      # (79EAC9E0-BAF9-11CE-8C82-00AA004BA90B)
      'e0c9ea79f9bace118c8200aa004ba90b',
      url.size  # Size of character array of the URL, including trailing zero
                # word (us). There are us/2-1 characters in the following
                # string.
    ].pack('H32V'), url
    if link.fragment
      frag = internal(link.fragment).dup << nullstr
      tail.push [frag.size / 2].pack('V'), frag
    end
    write_op opcode(:hlink), cell_range, guid, options, *tail
  end
  def write_hyperlink_table
    # TODO: theoretically it's possible to write fewer records by combining
    #       identical neighboring links in cell-ranges
    links = []
    @worksheet.each do |row|
      row.each_with_index do |cell, idx|
        if cell.is_a? Link
          write_hlink row.idx, idx, cell
        end
      end
    end
  end
  def write_iteration
    its = 0 # 0 = Iterations off; 1 = Iterations on
    write_op 0x0011, [its].pack('v')
  end
  ##
  # Write a cell with a String value. The String must have been stored in the
  # Shared String Table.
  def write_labelsst row, idx
    write_cell :labelsst, row, idx, @workbook.sst_index(self, row[idx])
  end
  ##
  # Write multiple consecutive blank cells.
  def write_mulblank row, idx, multiples
    data = [
      row.idx, # Index to row
      idx, # Index to first column (fc)
    ]
    # List of nc=lc-fc+1 16-bit indexes to XF records (➜ 6.115)
    multiples.each_with_index do |blank, cell_idx|
      xf_idx = @workbook.xf_index @worksheet.workbook, row.format(idx + cell_idx)
      data.push xf_idx
    end
    # Index to last column (lc)
    data.push idx + multiples.size - 1
    write_op opcode(:mulblank), data.pack('v*')
  end
  ##
  # Write multiple consecutive cells with RK values (see #write_rk)
  def write_mulrk row, idx, multiples
    fmt = 'v2'
    data = [
      row.idx, # Index to row
      idx, # Index to first column (fc)
    ]
    # List of nc=lc-fc+1 16-bit indexes to XF records (➜ 6.115)
    multiples.each_with_index do |cell, cell_idx|
      xf_idx = @workbook.xf_index @worksheet.workbook, row.format(idx + cell_idx)
      data.push xf_idx, encode_rk(cell)
      fmt << 'vV'
    end
    # Index to last column (lc)
    data.push idx + multiples.size - 1
    write_op opcode(:mulrk), data.pack(fmt << 'v')
  end
  def write_multiples row, idx, multiples
    case multiples.last
    when NilClass
      write_mulblank row, idx, multiples
    when Numeric
      if multiples.size > 1
        write_mulrk row, idx, multiples
      else
        write_rk row, idx
      end
    end
  end
  ##
  # Write a cell with a 64-bit double precision Float value
  def write_number row, idx
    # Offset Size Contents
    # 0 2 Index to row
    # 2 2 Index to column
    # 4 2 Index to XF record (➜ 6.115)
    # 6 8 IEEE 754 floating-point value (64-bit double precision)
    value = row[idx]
    case value
    when Date, Time
      value = encode_date(value)
    end
    write_cell :number, row, idx, value
  end
  def write_op op, *args
    data = args.join
    @io.write [op,data.size].pack("v2")
    @io.write data
  end
  def write_refmode
    # • The “RC” mode uses numeric indexes for rows and columns, for example
    #   “R(1)C(-1)”, or “R1C1:R2C2”.
    # • The “A1” mode uses characters for columns and numbers for rows, for
    #   example “B1”, or “$A$1:$B$2”.
    mode = 1 # 0 = RC mode; 1 = A1 mode
    write_op 0x000f, [mode].pack('v')
  end
  ##
  # Write a cell with a Numeric or Date value.
  def write_rk row, idx
    write_cell :rk, row, idx, encode_rk(row[idx])
  end
  def write_row row
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
    height = row.height || ROW_HEIGHT
    opts = row.outline_level & 0x00000007
    opts |= 0x00000010 if row.collapsed?
    opts |= 0x00000020 if row.hidden?
    opts |= 0x00000040 if height != ROW_HEIGHT
    if fmt = row.default_format
      xf_idx = @workbook.xf_index @worksheet.workbook, fmt
      opts |= 0x00000080
      opts |= xf_idx << 16
    end
    opts |= 0x00000100
    height = if height == ROW_HEIGHT
               (height * TWIPS).to_i | 0x8000
             else
               height * TWIPS
             end

    attrs = [
      row.idx,
      row.first_used,
      row.first_unused,
      height,
      opts]

    return if attrs.any?(&:nil?)

    # TODO: Row spacing
    data = attrs.pack binfmt(:row)
    write_op opcode(:row), data
  end
  def write_rowblock block
    # ●● ROW Properties of the used rows
    # ○○ Cell Block(s) Cell records for all used cells
    # ○  DBCELL Stream offsets to the cell records of each row
    block.each do |row|
      write_row row
    end
    block.each do |row|
      write_cellblocks row
    end
  end
  def write_rows
    row_blocks.each do |block|
      write_rowblock block
    end
  end
  def write_saverecalc
    # 0 = Do not recalculate; 1 = Recalculate before saving the document
    write_op 0x005f, [1].pack('v')
  end
  def write_window2
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
    flags = 0x0536  # Show grid lines, sheet headers, zero values. Automatic
                    # grid line colour, Remove slits if pane freeze is removed,
                    # Sheet is active.
    if @worksheet.selected
      flags |= 0x0200
    end
    flags |= 0x0080 # Show outline symbols, 
                    # but if [Row|Column]#outline_level = 0 the symbols are not shown.
    data = [ flags, 0, 0, 0, 0, 0 ].pack binfmt(:window2)
    write_op opcode(:window2), data
  end
  def write_wsbool
    bits = [
         #   Bit  Mask    Contents
      1, #     0  0x0001  0 = Do not show automatic page breaks
         #                1 = Show automatic page breaks
      0, #     4  0x0010  0 = Standard sheet
         #                1 = Dialogue sheet (BIFF5-BIFF8)
      0, #     5  0x0020  0 = No automatic styles in outlines
         #                1 = Apply automatic styles to outlines
      1, #     6  0x0040  0 = Outline buttons above outline group
         #                1 = Outline buttons below outline group
      1, #     7  0x0080  0 = Outline buttons left of outline group
         #                1 = Outline buttons right of outline group
      0, #     8  0x0100  0 = Scale printout in percent (➜ 6.89)
         #                1 = Fit printout to number of pages (➜ 6.89)
      0, #     9  0x0200  0 = Save external linked values
         #                    (BIFF3-BIFF4 only, ➜ 5.10)
         #                1 = Do not save external linked values
         #                    (BIFF3-BIFF4 only, ➜ 5.10)
      1, #    10  0x0400  0 = Do not show row outline symbols
         #                1 = Show row outline symbols
      0, #    11  0x0800  0 = Do not show column outline symbols
         #                1 = Show column outline symbols
      0, # 13-12  0x3000  These flags specify the arrangement of windows.
         #                They are stored in BIFF4 only.
         #                00 = Arrange windows tiled
         #                01 = Arrange windows horizontal
      0, #                10 = Arrange windows vertical
         #                11 = Arrange windows cascaded
         # The following flags are valid for BIFF4-BIFF8 only:
      0, #    14  0x4000  0 = Standard expression evaluation
         #                1 = Alternative expression evaluation
      0, #    15  0x8000  0 = Standard formula entries
         #                1 = Alternative formula entries
    ]
    weights = [4,5,6,7,8,9,10,11,12,13,14,15]
    value = bits.inject do |a, b| a | (b << weights.shift) end
    write_op 0x0081, [value].pack('v')
  end
end
    end
  end
end

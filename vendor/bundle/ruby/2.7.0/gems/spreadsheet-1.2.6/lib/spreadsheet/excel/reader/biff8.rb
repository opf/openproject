module Spreadsheet
  module Excel
    class Reader
##
# This Module collects reader methods such as read_string that are specific to
# Biff8.  This Module is likely to be expanded as Support for older Versions
# of Excel grows and methods get moved here for disambiguation.
module Biff8
  include Spreadsheet::Excel::Internals
  ##
  # When a String is too long for one Opcode, it is continued in a Continue
  # Opcode. Excel may reconsider compressing the remainder of the string.
  # This method appends the available remainder (decompressed if necessary) to
  # the incomplete string.
  def continue_string work, incomplete_string=@incomplete_string
    opts, _ = work.unpack 'C'
    wide = opts & 1
    head, chars = incomplete_string
    owing = chars - head.size / 2
    size = owing * (wide + 1)
    string = work[1, size]
    if wide == 0
      string = wide string
    end
    head << string
    if head.size >= chars * 2
      @incomplete_string = nil
    end
    size + 1
  end
  # When a String is too long for one Opcode, it is continued in a Continue
  # Opcode. Excel may reconsider compressing the remainder of the string.
  # This method appends the available remainder (decompressed if necessary) to
  # the incomplete string.
  def unpack_string work
    opts, _ = work.unpack 'C'
    wide = opts & 1
    string = work[1, -1]
    if wide == 0
      string = wide string
    end
  end
  ##
  # When a String is too long for one Opcode, it is continued in a Continue
  # Opcode. Excel may reconsider compressing the remainder of the string.
  # This method only evaluates the header and registers the address of the
  # continuation with the previous SstEntry.
  def continue_string_header work, oppos
    opts, _ = work.unpack 'C'
    wide = opts & 1
    owing = @incomplete_sst.continued_chars
    size = [work.size, owing * (1 + wide) + 1].min
    chars = (size - 1) / (1 + wide)
    skip = size
    @incomplete_sst.continue oppos + OPCODE_SIZE, size, chars
    unless @incomplete_sst.continued?
      @workbook.add_shared_string @incomplete_sst
      skip += @incomplete_skip
      @incomplete_sst = nil
      @incomplete_skip = nil
    end
    skip
  end
  ##
  # Read more data into the Shared String Table. (see also: #read_sst)
  # This method only evaluates the header, the actual work is done in #_read_sst
  def continue_sst work, oppos, len
    pos = 0
    if @incomplete_sst
      pos = continue_string_header work, oppos
    elsif !@incomplete_skip.nil?
      pos =  @incomplete_skip
      @incomplete_skip = nil
    end
    @sst_offset[1] += len
    _read_sst work, oppos, pos
  end
  def postread_workbook # :nodoc:
    super
    @incomplete_string, @sst_size, @sst_offset, @incomplete_sst = nil, @incomplete_skip = nil
  end
  ##
  # Store the offset of extsst, so we can write a new extsst when the
  # sst has changed
  def read_extsst work, pos, len
    @workbook.offsets.store :extsst, [pos, len]
  end
  ##
  # Read the Shared String Table present in all Biff8 Files.
  # This method only evaluates the header, the actual work is done in #_read_sst
  def read_sst work, pos, len
    # Offset  Size  Contents
    #      0     4  Total number of strings in the workbook (see below)
    #      4     4  Number of following strings (nm)
    #      8  var.  List of nm Unicode strings, 16-bit string length (➜ 3.4)
    _, @sst_size = work.unpack 'V2'
    @sst_offset = [pos, len]
    @workbook.offsets.store :sst, @sst_offset
    _read_sst work, pos, 8
  end
  ##
  # Read a string from the Spreadsheet, such as a Worksheet- or Font-Name, or a
  # Number-Format. See also #read_string_header and #read_string_body
  def read_string work, count_length=1
    #   Offset    Size  Contents
    #        0  1 or 2  Length of the string (character count, ln)
    #   1 or 2       1  Option flags:
    #                   Bit  Mask  Contents
    #                     0  0x01  Character compression (ccompr):
    #                              0 = Compressed (8-bit characters)
    #                              1 = Uncompressed (16-bit characters)
    #                     2  0x04  Asian phonetic settings (phonetic):
    #                              0 = Does not contain Asian phonetic settings
    #                              1 = Contains Asian phonetic settings
    #                     3  0x08  Rich-Text settings (richtext):
    #                              0 = Does not contain Rich-Text settings
    #                              1 = Contains Rich-Text settings
    # [2 or 3]       2  (optional, only if richtext=1)
    #                   Number of Rich-Text formatting runs (rt)
    #   [var.]       4  (optional, only if phonetic=1)
    #                   Size of Asian phonetic settings block (in bytes, sz)
    #     var.      ln  Character array (8-bit characters
    #          or 2∙ln               or 16-bit characters, dependent on ccompr)
    #   [var.]    4∙rt  (optional, only if richtext=1)
    #                   List of rt formatting runs (➜ 3.2)
    #   [var.]      sz  (optional, only if phonetic=1)
    #                   Asian Phonetic Settings Block (➜ 3.4.2)
    chars, offset, wide, _, _, available, owing, _ = read_string_header work, count_length
    string, _ = read_string_body work, offset, available, wide > 0
    if owing > 0
      @incomplete_string = [string, chars]
    end
    string
  end
  ##
  # Read the body of a string. Returns the String (decompressed if necessary) and
  # the available data (unchanged).
  def read_string_body work, offset, available, wide
    data = work[offset, available]
    widened_data = wide ? data : wide(data)
    [widened_data, data]
  end
  ##
  # Read the header of a string. Returns the following information in an Array:
  # * The total number of characters in the string
  # * The offset of the actual string data (= the length of this header in bytes)
  # * Whether or not the string was compressed (0/1)
  # * Whether or not the string contains asian phonetic settings (0/1)
  # * Whether or not the string contains richtext formatting (0/1)
  # * The number of bytes containing characters in this chunk of data
  # * The number of characters missing from this chunk of data and expected to
  #   follow in a Continue Opcode
  def read_string_header work, count_length=1, offset=0
    fmt = count_length == 1 ? 'C2' : 'vC'
    chars, opts = work[offset, 1 + count_length].unpack fmt
    wide      = opts & 1
    phonetic  = (opts >> 2) & 1
    richtext  = (opts >> 3) & 1
    size      = chars * (wide + 1)
    skip = 0
    if richtext > 0
      runs, = work[offset + 1 + count_length, 2].unpack 'v'
      skip = 4 * runs
    end
    if phonetic > 0
      psize, = work[offset + 1 + count_length + richtext * 2, 4].unpack 'V'
      skip += psize
    end
    flagsize  = 1 + count_length + richtext * 2 + phonetic * 4
    avbl      = [work.size - offset, flagsize + size].min
    have_chrs = (avbl - flagsize) / (1 + wide)
    owing     = chars - have_chrs
    [chars, flagsize, wide, phonetic, richtext, avbl, owing, skip]
  end

  def read_range_address_list work, len
    # Cell range address, BIFF8:
    # Offset  Size  Contents
    # 0       2     Index to first row
    # 2       2     Index to last row
    # 4       2     Index to first column
    # 6       2     Index to last column
    # ! In several cases, BIFF8 still writes the BIFF2-BIFF5 format of a cell range address
    # (using 8-bit values for the column indexes). This will be mentioned at the respective place.
    #
    offset = 0, results = []
    return results if len < 2
    count = work[0..1].unpack('v').first
    offset = 2
    count.times do |i|
      results << work[offset...offset+8].unpack('v4')
      offset += 8
    end
    results
  end
  ##
  # Insert null-characters into a compressed UTF-16 string
  def wide string
    data = ''.dup
    string.each_byte do |byte| data << byte.chr << 0.chr end
    data
  end
  private
  ##
  # Read the Shared String Table present in all Biff8 Files.
  def _read_sst work, oppos, pos
    worksize = work.size
    while @workbook.sst_size < @sst_size && pos < worksize do
      sst = SstEntry.new :offset => oppos + OPCODE_SIZE + pos,
                         :ole    => @data,
                         :reader => self
      sst.chars, sst.flags, wide, sst.phonetic, sst.richtext, sst.available,
        sst.continued_chars, skip = read_string_header work, 2, pos
      sst.wide = wide > 0
      if sst.continued?
        @incomplete_sst = sst
        @incomplete_skip = skip
        pos += sst.available
      else
        @workbook.add_shared_string sst
        pos += sst.available + skip
        if pos > worksize
          @incomplete_skip = pos - worksize
        end
      end
    end
  end
end
    end
  end
end

module Spreadsheet
  module Excel
    class Reader
##
# This Module collects reader methods such as read_string that are specific to
# Biff5.  This Module is likely to be expanded as Support for older Versions
# of Excel grows.
module Biff5
  ##
  # Read a String of 8-bit Characters
  def read_string work, count_length=1
    # Offset    Size  Contents
    #      0  1 or 2  Length of the string (character count, ln)
    # 1 or 2      ln  Character array (8-bit characters)
    fmt = count_length == 1 ? 'C' : 'v'
    length, = work.unpack fmt
    work[count_length, length]
  end

  def read_range_address_list work, len
    # Cell range address, BIFF2-BIFF5:
    # Offset  Size  Contents
    # 0       2     Index to first row
    # 2       2     Index to last row
    # 4       1     Index to first column
    # 5       1     Index to last column
    #
    offset = 0, results = []
    return results if len < 2
    count = work[0..1].unpack('v').first
    offset = 2
    count.times do |i|
      results << work[offset...offset+6].unpack('v2c2')
      offset += 6
    end
    results
  end

end
    end
  end
end

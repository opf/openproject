require 'spreadsheet/encodings'

module Spreadsheet
  module Excel
    module Writer
##
# This Module collects writer methods such as unicode_string that are specific
# to Biff8. This Module is likely to be expanded as Support for older Versions
# of Excel grows and methods get moved here for disambiguation.
module Biff8
  include Spreadsheet::Encodings
  ##
  # Check whether the string _data_ can be compressed (i.e. every second byte
  # is a Null-byte) and perform compression.
  # Returns the data and compression_status (0/1)
  def compress_unicode_string data
    compressed = internal('')
    expect_null = false
    data.each_byte do |byte|
      if expect_null
        if byte != 0
          return [data, 1] # 1 => Data consists of wide Chars
        end
        expect_null = false
      else
        compressed << byte
        expect_null = true
      end
    end
    [compressed, 0] # 0 => Data consists of compressed Chars
  end
  ##
  # Encode _string_ into a Biff8 Unicode String. Header and body are encoded
  # separately by #_unicode_string. This method simply combines the two.
  def unicode_string string, count_length=1
    header, data, _ = _unicode_string string, count_length
    header << data
  end
  @@bytesize = RUBY_VERSION >= '1.9' ? :bytesize : :size
  ##
  # Encode _string_ into a Biff8 Unicode String Header and Body.
  def _unicode_string string, count_length=1
    data = internal string
    size = data.send(@@bytesize) / 2
    fmt = count_length == 1 ? 'C2' : 'vC'
    data, wide = compress_unicode_string data
    opts = wide
    header = [
      size, # Length of the string (character count, ln)
      opts, # Option flags:
            # Bit  Mask  Contents
            #   0  0x01  Character compression (ccompr):
            #            0 = Compressed (8-bit characters)
            #            1 = Uncompressed (16-bit characters)
            #   2  0x04  Asian phonetic settings (phonetic):
            #            0 = Does not contain Asian phonetic settings
            #            1 = Contains Asian phonetic settings
            #   3  0x08  Rich-Text settings (richtext):
            #            0 = Does not contain Rich-Text settings
            #            1 = Contains Rich-Text settings
      #0x00,# (optional, only if richtext=1) Number of Rich-Text
            #                                formatting runs (rt)
      #0x00,# (optional, only if phonetic=1) Size of Asian phonetic
            #                                settings block (in bytes, sz)
    ].pack fmt
    data << '' # (optional, only if richtext=1)
               # List of rt formatting runs (➜ 3.2)
    data << '' # (optional, only if phonetic=1)
               # Asian Phonetic Settings Block (➜ 3.4.2)
    [header, data, wide]
  end
end
    end
  end
end

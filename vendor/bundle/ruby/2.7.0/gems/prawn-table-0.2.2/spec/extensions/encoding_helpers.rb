# encoding: utf-8

module EncodingHelpers
  def win1252_string(str)
    str.force_encoding(Encoding::Windows_1252)
  end

  def bin_string(str)
    str.force_encoding(Encoding::ASCII_8BIT)
  end
end

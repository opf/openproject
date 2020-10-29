# frozen_string_literal: true

module EncodingHelpers
  def win1252_string(str)
    str.dup.force_encoding(Encoding::Windows_1252)
  end

  def bin_string(str)
    str.dup.force_encoding(Encoding::ASCII_8BIT)
  end
end

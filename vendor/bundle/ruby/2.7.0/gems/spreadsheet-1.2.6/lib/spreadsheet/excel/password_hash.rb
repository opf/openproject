module Spreadsheet
  module Excel
module Password
  class <<self
    ##
    # Makes an excel-compatible hash
    def password_hash(password)
      hash = 0
      password.chars.reverse_each { |chr| hash = rol15(hash ^ chr[0].ord) }
      hash ^ password.size ^ 0xCE4B
    end

    private
    ##
    # rotates hash 1 bit left, using lower 15 bits
    def rol15(hash)
      new_hash = hash << 1
      (new_hash & 0x7FFF) | (new_hash >> 15)
    end
  end

end
  end
end

# frozen_string_literal: true

module Plaintext
  module CodesetUtil
    def self.to_utf8(str, encoding)
      return str if str.nil?
      str.force_encoding('ASCII-8BIT')
      if str.empty?
        str.force_encoding('UTF-8')
        return str
      end
      enc = (encoding.nil? || encoding.size == 0) ? 'UTF-8' : encoding
      if enc.upcase != 'UTF-8'
        str.force_encoding(enc)
        str = str.encode('UTF-8', invalid: :replace,
                         undef: :replace, replace: '?')
      else
        str.force_encoding('UTF-8')
        if !str.valid_encoding?
          str = str.encode('US-ASCII', invalid: :replace,
                           undef: :replace, replace: '?').encode('UTF-8')
        end
      end
      str
    end
  end
end
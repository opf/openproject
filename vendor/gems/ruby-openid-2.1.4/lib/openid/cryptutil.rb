require "openid/util"
require "digest/sha1"
require "digest/sha2"
begin
  require "digest/hmac"
rescue LoadError
  require "hmac/sha1"
  require "hmac/sha2"
end

module OpenID
  # This module contains everything needed to perform low-level
  # cryptograph and data manipulation tasks.
  module CryptUtil

    # Generate a random number, doing a little extra work to make it
    # more likely that it's suitable for cryptography. If your system
    # doesn't have /dev/urandom then this number is not
    # cryptographically safe. See
    # <http://www.cosine.org/2007/08/07/security-ruby-kernel-rand/>
    # for more information.  max is the largest possible value of such
    # a random number, where the result will be less than max.
    def CryptUtil.rand(max)
      Kernel.srand()
      return Kernel.rand(max)
    end

    def CryptUtil.sha1(text)
      return Digest::SHA1.digest(text)
    end

    def CryptUtil.hmac_sha1(key, text)
      if Digest.const_defined? :HMAC      
        Digest::HMAC.new(key,Digest::SHA1).update(text).digest
      else
        return HMAC::SHA1.digest(key, text)
      end
    end

    def CryptUtil.sha256(text)
      return Digest::SHA256.digest(text)
    end

    def CryptUtil.hmac_sha256(key, text)
      if Digest.const_defined? :HMAC      
        Digest::HMAC.new(key,Digest::SHA256).update(text).digest
      else
        return HMAC::SHA256.digest(key, text)
      end
    end

    # Generate a random string of the given length, composed of the
    # specified characters.  If chars is nil, generate a string
    # composed of characters in the range 0..255.
    def CryptUtil.random_string(length, chars=nil)
      s = ""

      unless chars.nil?
        length.times { s << chars[rand(chars.length)] }
      else
        length.times { s << rand(256).chr }
      end
      return s
    end

    # Convert a number to its binary representation; return a string
    # of bytes.
    def CryptUtil.num_to_binary(n)
      bits = n.to_s(2)
      prepend = (8 - bits.length % 8)
      bits = ('0' * prepend) + bits
      return [bits].pack('B*')
    end

    # Convert a string of bytes into a number.
    def CryptUtil.binary_to_num(s)
      # taken from openid-ruby 0.0.1
      s = "\000" * (4 - (s.length % 4)) + s
      num = 0
      s.unpack('N*').each do |x|
        num <<= 32
        num |= x
      end
      return num
    end

    # Encode a number as a base64-encoded byte string.
    def CryptUtil.num_to_base64(l)
      return OpenID::Util.to_base64(num_to_binary(l))
    end

    # Decode a base64 byte string to a number.
    def CryptUtil.base64_to_num(s)
      return binary_to_num(OpenID::Util.from_base64(s))
    end
  end
end

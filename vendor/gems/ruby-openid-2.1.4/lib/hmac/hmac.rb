# Copyright (C) 2001  Daiki Ueno <ueno@unixuser.org>
# This library is distributed under the terms of the Ruby license.

# This module provides common interface to HMAC engines.
# HMAC standard is documented in RFC 2104:
#
#   H. Krawczyk et al., "HMAC: Keyed-Hashing for Message Authentication",
#   RFC 2104, February 1997
#
# These APIs are inspired by JCE 1.2's javax.crypto.Mac interface.
#
#   <URL:http://java.sun.com/security/JCE1.2/spec/apidoc/javax/crypto/Mac.html>

module HMAC
  class Base
    def initialize(algorithm, block_size, output_length, key)
      @algorithm = algorithm
      @block_size = block_size
      @output_length = output_length
      @status = STATUS_UNDEFINED
      @key_xor_ipad = ''
      @key_xor_opad = ''
      set_key(key) unless key.nil?
    end

    private
    def check_status
      unless @status == STATUS_INITIALIZED
	raise RuntimeError,
	  "The underlying hash algorithm has not yet been initialized."
      end
    end

    public
    def set_key(key)
      # If key is longer than the block size, apply hash function
      # to key and use the result as a real key.
      key = @algorithm.digest(key) if key.size > @block_size
      key_xor_ipad = "\x36" * @block_size
      key_xor_opad = "\x5C" * @block_size
      for i in 0 .. key.size - 1
	key_xor_ipad[i] ^= key[i]
	key_xor_opad[i] ^= key[i]
      end
      @key_xor_ipad = key_xor_ipad
      @key_xor_opad = key_xor_opad
      @md = @algorithm.new
      @status = STATUS_INITIALIZED
    end

    def reset_key
      @key_xor_ipad.gsub!(/./, '?')
      @key_xor_opad.gsub!(/./, '?')
      @key_xor_ipad[0..-1] = ''
      @key_xor_opad[0..-1] = ''
      @status = STATUS_UNDEFINED
    end

    def update(text)
      check_status
      # perform inner H
      md = @algorithm.new
      md.update(@key_xor_ipad)
      md.update(text)
      str = md.digest
      # perform outer H
      md = @algorithm.new
      md.update(@key_xor_opad)
      md.update(str)
      @md = md
    end
    alias << update

    def digest
      check_status
      @md.digest
    end

    def hexdigest
      check_status
      @md.hexdigest
    end
    alias to_s hexdigest

    # These two class methods below are safer than using above
    # instance methods combinatorially because an instance will have
    # held a key even if it's no longer in use.
    def Base.digest(key, text)
      begin
	hmac = self.new(key)
	hmac.update(text)
	hmac.digest
      ensure
	hmac.reset_key
      end
    end

    def Base.hexdigest(key, text)
      begin
	hmac = self.new(key)
	hmac.update(text)
	hmac.hexdigest
      ensure
	hmac.reset_key
      end
    end

    private_class_method :new, :digest, :hexdigest
  end

  STATUS_UNDEFINED, STATUS_INITIALIZED = 0, 1
end

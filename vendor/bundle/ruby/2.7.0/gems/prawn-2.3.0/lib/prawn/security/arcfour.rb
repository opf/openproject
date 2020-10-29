# frozen_string_literal: true

# Implementation of the "ARCFOUR" algorithm ("alleged RC4 (tm)"). Implemented
# as described at:
# http://www.mozilla.org/projects/security/pki/nss/draft-kaukonen-cipher-arcfour-03.txt
#
# "RC4" is a trademark of RSA Data Security, Inc.
#
# Copyright August 2009, Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

# @private
class Arcfour
  def initialize(key)
    # Convert string key to Array of integers
    key = key.unpack('c*') if key.is_a?(String)

    # 1. Allocate an 256 element array of 8 bit bytes to be used as an S-box
    # 2. Initialize the S-box.  Fill each entry first with it's index
    @sbox = (0..255).to_a

    # 3. Fill another array of the same size (256) with the key, repeating
    #    bytes as necessary.
    s2 = []
    while s2.length < 256
      s2 += key
    end
    s2 = s2[0, 256]

    # 4. Set j to zero and initialize the S-box
    j = 0
    (0..255).each do |i|
      j = (j + @sbox[i] + s2[i]) % 256
      @sbox[i], @sbox[j] = @sbox[j], @sbox[i]
    end

    @i = @j = 0
  end

  def encrypt(string)
    string.unpack('c*').map { |byte| byte ^ key_byte }.pack('c*')
  end

  private

  # Produces the next byte of key material in the stream (3.2 Stream Generation)
  def key_byte
    @i = (@i + 1) % 256
    @j = (@j + @sbox[@i]) % 256
    @sbox[@i], @sbox[@j] = @sbox[@j], @sbox[@i]
    @sbox[(@sbox[@i] + @sbox[@j]) % 256]
  end
end

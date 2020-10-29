require 'openssl'

##
# A Ruby implementation of AES Key Wrap, a.k.a RFC 3394, a.k.a NIST Key Wrapping
#
module AESKeyWrap
  DEFAULT_IV = 0xA6A6A6A6A6A6A6A6
  IV_SIZE = 8 # bytes

  UnwrapFailedError = Class.new(StandardError)

  class << self

    ##
    # Wraps a key using a key-encrypting key (KEK)
    #
    # This is an implementation of the "index based" algorithm
    # specified in section 2.2.1 of RFC 3394:
    # http://www.ietf.org/rfc/rfc3394.txt
    #
    # @param unwrapped_key [String] The plaintext key to be wrapped, as a binary string
    # @param kek [String] The key-encrypting key, as a binary_string
    # @param iv [Integer, String] The "initial value", as either an unsigned
    #   64-bit integer (e.g. `0xDEADBEEFC0FFEEEE`) or an 8-byte string (e.g.
    #   `"\xDE\xAD\xBE\xEF\xC0\xFF\xEE\xEE"`).
    # @return [String] The wrapped key, as a binary string
    #
    def wrap(unwrapped_key, kek, iv=DEFAULT_IV)
      # 1) Initialize variables.
      #
      #    P: buffer (from unwrapped_key)
      #    A: buffer[0]
      #    R: buffer
      #    K: kek
      #    n: block_count
      #    AES: aes(:encrypt, _, _)
      #    IV: iv
      buffer = [coerce_uint64(iv)] + unwrapped_key.unpack('Q>*')
      block_count = buffer.size - 1

      # 2) Calculate intermediate values.
      # t: round
      0.upto(5) do |j|
        1.upto(block_count) do |i|
          round = block_count*j + i
          # In
          data = [buffer[0], buffer[i]].pack('Q>2')
          buffer[0], buffer[i] = aes(:encrypt, kek, data).unpack('Q>2')
          # Enc
          buffer[0] = buffer[0] ^ round
          # XorT
        end
      end

      # 3) Output the results.
      buffer.pack('Q>*')
    end

    ##
    # Unwraps an encrypted key using a key-encrypting key (KEK)
    #
    # This is an implementation of the "index based" algorithm
    # specified in section 2.2.2 of RFC 3394:
    # http://www.ietf.org/rfc/rfc3394.txt
    #
    # @param wrapped_key [String] The wrapped key (cyphertext), as a binary string
    # @param kek [String] The key-encrypting key, as a binary string
    # @param expected_iv [Integer, String] The IV used to wrap the key, as either
    #   an unsigned 64-bit integer (e.g. `0xDEADBEEFC0FFEEEE`) or an 8-byte
    #   string (e.g. `"\xDE\xAD\xBE\xEF\xC0\xFF\xEE\xEE"`).
    # @return [String] The unwrapped (plaintext) key as a binary string, or
    #   `nil` if unwrapping failed due to `expected_iv` not matching the
    #   decrypted IV
    #
    # @see #unwrap!
    #
    def unwrap(wrapped_key, kek, expected_iv=DEFAULT_IV)
      # 1) Initialize variables.
      #
      #    C: buffer (from wrapped_key)
      #    A: buffer[0]
      #    R: buffer
      #    n: block_count
      #    K: kek
      #    AES-1: aes(:decrypt, _, _)
      buffer = wrapped_key.unpack('Q>*')
      block_count = buffer.size - 1

      # 2) Calculate intermediate values.
      # t: round
      5.downto(0) do |j|
        block_count.downto(1) do |i|
          round = block_count*j + i
          # In
          buffer[0] = buffer[0] ^ round
          # XorT
          data = [buffer[0], buffer[i]].pack('Q>2')
          buffer[0], buffer[i] = aes(:decrypt, kek, data).unpack('Q>2')
          # Dec
        end
      end

      # 3) Output the results.
      if buffer[0] == coerce_uint64(expected_iv)
        buffer.drop(1).pack('Q>*')
      else
        nil
      end
    end

    ##
    # Exception-throwing version of #unwrap
    #
    # @see #unwrap
    #
    def unwrap!(*args)
      unwrap(*args) || raise(UnwrapFailedError, 'Unwrapped IV does not match')
    end

    private

      MAX_UINT64 = 0xFFFFFFFFFFFFFFFF

      def aes(encrypt_or_decrypt, key, data)
        decipher = OpenSSL::Cipher::AES.new(key.bytesize * 8, :ECB)
        decipher.send(encrypt_or_decrypt)
        decipher.key = key
        decipher.padding = 0

        decipher.update(data) + decipher.final
      end

      def coerce_uint64(value)
        case value
        when Integer
          if value > MAX_UINT64
            raise ArgumentError, "IV is too large to fit in a 64-bit unsigned integer"
          elsif value < 0
            raise ArgumentError, "IV is not an unsigned integer (it's negative)"
          else
            value
          end
        when String
          if value.bytesize == IV_SIZE
            value.unpack("Q>").first
          else
            raise ArgumentError, "IV is not #{IV_SIZE} bytes long"
          end
        else
          raise ArgumentError, "IV is not valid: #{value.inspect}"
        end
      end
  end
end


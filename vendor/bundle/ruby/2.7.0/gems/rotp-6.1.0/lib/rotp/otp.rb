module ROTP
  class OTP
    attr_reader :secret, :digits, :digest
    DEFAULT_DIGITS = 6

    # @param [String] secret in the form of base32
    # @option options digits [Integer] (6)
    #     Number of integers in the OTP.
    #     Google Authenticate only supports 6 currently
    # @option options digest [String] (sha1)
    #     Digest used in the HMAC.
    #     Google Authenticate only supports 'sha1' currently
    # @returns [OTP] OTP instantiation
    def initialize(s, options = {})
      @digits = options[:digits] || DEFAULT_DIGITS
      @digest = options[:digest] || 'sha1'
      @secret = s
    end

    # @param [Integer] input the number used seed the HMAC
    # @option padded [Boolean] (false) Output the otp as a 0 padded string
    # Usually either the counter, or the computed integer
    # based on the Unix timestamp
    def generate_otp(input)
      hmac = OpenSSL::HMAC.digest(
        OpenSSL::Digest.new(digest),
        byte_secret,
        int_to_bytestring(input)
      )

      offset = hmac[-1].ord & 0xf
      code = (hmac[offset].ord & 0x7f) << 24 |
             (hmac[offset + 1].ord & 0xff) << 16 |
             (hmac[offset + 2].ord & 0xff) << 8 |
             (hmac[offset + 3].ord & 0xff)
      (code % 10**digits).to_s.rjust(digits, '0')
    end

    private

    def verify(input, generated)
      raise ArgumentError, '`otp` should be a String' unless
          input.is_a?(String)

      time_constant_compare(input, generated)
    end

    def byte_secret
      Base32.decode(@secret)
    end

    # Turns an integer to the OATH specified
    # bytestring, which is fed to the HMAC
    # along with the secret
    #
    def int_to_bytestring(int, padding = 8)
      unless int >= 0
        raise ArgumentError, '#int_to_bytestring requires a positive number'
      end

      result = []
      until int == 0
        result << (int & 0xFF).chr
        int >>= 8
      end
      result.reverse.join.rjust(padding, 0.chr)
    end

    # constant-time compare the strings
    def time_constant_compare(a, b)
      return false if a.empty? || b.empty? || a.bytesize != b.bytesize

      l = a.unpack "C#{a.bytesize}"
      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end
end

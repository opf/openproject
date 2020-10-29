# frozen_string_literal: true

module TTFunk
  class Table
    class Dsig < Table
      class SignatureRecord
        attr_reader :format, :length, :offset, :signature

        def initialize(format, length, offset, signature)
          @format = format
          @length = length
          @offset = offset
          @signature = signature
        end
      end

      attr_reader :version, :flags, :signatures

      TAG = 'DSIG'

      def self.encode(dsig)
        return nil unless dsig

        # Don't attempt to re-sign or anything - just use dummy values.
        # Since we're subsetting that should be permissible.
        [dsig.version, 0, 0].pack('Nnn')
      end

      def tag
        TAG
      end

      private

      def parse!
        @version, num_signatures, @flags = read(8, 'Nnn')

        @signatures = Array.new(num_signatures) do
          format, length, sig_offset = read(12, 'N3')
          signature = parse_from(offset + sig_offset) do
            _, _, sig_length = read(8, 'nnN')
            read(sig_length, 'C*')
          end

          SignatureRecord.new(format, length, sig_offset, signature)
        end
      end
    end
  end
end

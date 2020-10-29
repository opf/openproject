# frozen_string_literal: true

require 'bigdecimal'

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class Dict < TTFunk::SubTable
        class InvalidOperandError < StandardError; end
        class TooManyOperandsError < StandardError; end

        # for regular single-byte operators
        OPERATOR_BZERO = (0..21).freeze
        OPERAND_BZERO = [28..30, 32..254].freeze

        # for operators that are two bytes wide
        WIDE_OPERATOR_BZERO = 12
        WIDE_OPERATOR_ADJUSTMENT = 1200

        # maximum number of operands allowed per operator
        MAX_OPERANDS = 48

        # used to validate operands expressed in scientific notation
        VALID_SCI_SIGNIFICAND_RE = /\A-?(\.\d+|\d+|\d+\.\d+)\z/.freeze
        VALID_SCI_EXPONENT_RE = /\A-?\d+\z/.freeze

        include Enumerable

        def [](operator)
          @dict[operator]
        end

        def each(&block)
          @dict.each(&block)
        end

        alias each_pair each

        def encode
          map do |(operator, operands)|
            operands.map { |operand| encode_operand(operand) }.join +
              encode_operator(operator)
          end.join
        end

        private

        def encode_operator(operator)
          if operator >= WIDE_OPERATOR_ADJUSTMENT
            [
              WIDE_OPERATOR_BZERO,
              operator - WIDE_OPERATOR_ADJUSTMENT
            ].pack('C*')
          else
            [operator].pack('C')
          end
        end

        def encode_operand(operand)
          case operand
          when Integer
            encode_integer(operand)
          when Float, BigDecimal
            encode_float(operand)
          when SciForm
            encode_sci(operand)
          end
        end

        def encode_integer(int)
          case int
          when -107..107
            [int + 139].pack('C')

          when 108..1131
            int -= 108
            [(int >> 8) + 247, int & 0xFF].pack('C*')

          when -1131..-108
            int = -int - 108
            [(int >> 8) + 251, int & 0xFF].pack('C*')

          when -32_768..32_767
            [28, (int >> 8) & 0xFF, int & 0xFF].pack('C*')

          else
            encode_integer32(int)
          end
        end

        def encode_integer32(int)
          [29, int].pack('CN')
        end

        def encode_float(float)
          pack_decimal_nibbles(encode_significand(float))
        end

        def encode_sci(sci)
          sig_bytes = encode_significand(sci.significand)
          exp_bytes = encode_exponent(sci.exponent)
          pack_decimal_nibbles(sig_bytes + exp_bytes)
        end

        def encode_exponent(exp)
          return [] if exp == 0

          [exp > 0 ? 0xB : 0xC, *encode_significand(exp.abs)]
        end

        def encode_significand(sig)
          sig.to_s.each_char.with_object([]) do |char, ret|
            case char
            when '0'..'9'
              ret << char.to_i
            when '.'
              ret << 0xA
            when '-'
              ret << 0xE
            else
              break ret
            end
          end
        end

        def pack_decimal_nibbles(nibbles)
          bytes = [30]

          nibbles.each_slice(2).each do |(high_nb, low_nb)|
            # low_nb can be nil if nibbles contains an odd number of elements
            low_nb ||= 0xF
            bytes << (high_nb << 4 | low_nb)
          end

          bytes << 0xFF if nibbles.size.even?
          bytes.pack('C*')
        end

        def parse!
          @dict = {}
          operands = []

          # @length must be set via the constructor
          while io.pos < table_offset + length
            case b_zero = read(1, 'C').first
            when WIDE_OPERATOR_BZERO
              operator = decode_wide_operator
              @dict[operator] = operands
              operands = []
            when OPERATOR_BZERO
              @dict[b_zero] = operands unless operands.empty?
              operands = []
            when *OPERAND_BZERO
              operands << decode_operand(b_zero)

              if operands.size > MAX_OPERANDS
                raise TooManyOperandsError, 'found one too many operands at '\
                  "position #{io.pos} in dict at position #{table_offset}"
              end
            else
              raise "dict byte value #{b_zero} is reserved"
            end
          end
        end

        def decode_wide_operator
          WIDE_OPERATOR_ADJUSTMENT + read(1, 'C').first
        end

        def decode_operand(b_zero)
          case b_zero
          when 30
            decode_sci
          else
            decode_integer(b_zero)
          end
        end

        def decode_sci
          significand = ''.b
          exponent = ''.b

          loop do
            current = read(1, 'C').first
            break if current == 0xFF

            high_nibble = current >> 4
            low_nibble = current & 0x0F # 0b00001111

            [high_nibble, low_nibble].each do |nibble|
              case nibble
              when 0..9
                (exponent.empty? ? significand : exponent) << nibble.to_s
              when 0xA
                significand << '.'
              when 0xB
                # take advantage of Integer#to_i not caring about whitespace
                exponent << ' '
              when 0xC
                exponent << '-'
              when 0xE
                significand << '-'
              end
            end

            break if low_nibble == 0xF
          end

          validate_sci!(significand, exponent)

          SciForm.new(significand.to_f, exponent.to_i)
        end

        def validate_sci!(significand, exponent)
          unless valid_significand?(significand) && valid_exponent?(exponent)
            raise InvalidOperandError,
              'invalid scientific notation operand with significand '\
              "'#{significand}' and exponent '#{exponent}' ending at "\
              "position #{io.pos} in dict at position #{table_offset}"
          end
        end

        def valid_significand?(significand)
          !(significand.strip =~ VALID_SCI_SIGNIFICAND_RE).nil?
        end

        def valid_exponent?(exponent)
          exponent = exponent.strip
          return true if exponent.empty?

          !(exponent.strip =~ VALID_SCI_EXPONENT_RE).nil?
        end

        def decode_integer(b_zero)
          case b_zero
          when 32..246
            # 1 byte
            b_zero - 139

          when 247..250
            # 2 bytes
            b_one = read(1, 'C').first
            (b_zero - 247) * 256 + b_one + 108

          when 251..254
            # 2 bytes
            b_one = read(1, 'C').first
            -(b_zero - 251) * 256 - b_one - 108

          when 28
            # 2 bytes in number (3 total)
            b_one, b_two = read(2, 'C*')
            BinUtils.twos_comp_to_int(b_one << 8 | b_two, bit_width: 16)

          when 29
            # 4 bytes in number (5 total)
            b_one, b_two, b_three, b_four = read(4, 'C*')
            BinUtils.twos_comp_to_int(
              b_one << 24 | b_two << 16 | b_three << 8 | b_four, bit_width: 32
            )
          end
        end
      end
    end
  end
end

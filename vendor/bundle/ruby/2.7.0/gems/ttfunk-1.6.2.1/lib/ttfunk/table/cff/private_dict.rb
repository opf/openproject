# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class PrivateDict < TTFunk::Table::Cff::Dict
        DEFAULT_WIDTH_X_DEFAULT = 0
        DEFAULT_WIDTH_X_NOMINAL = 0
        PLACEHOLDER_LENGTH = 5

        OPERATORS = {
          subrs: 19,
          default_width_x: 20,
          nominal_width_x: 21
        }.freeze

        OPERATOR_CODES = OPERATORS.invert

        # @TODO: use mapping to determine which subroutines are still used.
        # For now, just encode them all.
        def encode(_mapping)
          EncodedString.new do |result|
            each do |operator, operands|
              case OPERATOR_CODES[operator]
              when :subrs
                result << encode_subrs
              else
                operands.each { |operand| result << encode_operand(operand) }
              end

              result << encode_operator(operator)
            end
          end
        end

        def finalize(private_dict_data)
          return unless subr_index

          encoded_subr_index = subr_index.encode
          encoded_offset = encode_integer32(private_dict_data.length)

          private_dict_data.resolve_placeholder(
            :"subrs_#{@table_offset}", encoded_offset
          )

          private_dict_data << encoded_subr_index
        end

        def subr_index
          @subr_index ||=
            if (subr_offset = self[OPERATORS[:subrs]])
              SubrIndex.new(file, table_offset + subr_offset.first)
            end
        end

        def default_width_x
          if (width = self[OPERATORS[:default_width_x]])
            width.first
          else
            DEFAULT_WIDTH_X_DEFAULT
          end
        end

        def nominal_width_x
          if (width = self[OPERATORS[:nominal_width_x]])
            width.first
          else
            DEFAULT_WIDTH_X_NOMINAL
          end
        end

        private

        def encode_subrs
          EncodedString.new.tap do |result|
            result << Placeholder.new(
              :"subrs_#{@table_offset}", length: PLACEHOLDER_LENGTH
            )
          end
        end
      end
    end
  end
end

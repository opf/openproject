# frozen_string_literal: true

require_relative '../../reader'

module TTFunk
  class Table
    class Glyf
      class Simple
        attr_reader :id, :raw
        attr_reader :number_of_contours
        attr_reader :x_min, :y_min, :x_max, :y_max
        attr_reader :end_points_of_contours
        attr_reader :instruction_length, :instructions

        def initialize(id, raw)
          @id = id
          @raw = raw
          io = StringIO.new(raw)

          @number_of_contours, @x_min, @y_min, @x_max, @y_max =
            io.read(10).unpack('n*').map do |i|
              BinUtils.twos_comp_to_int(i, bit_width: 16)
            end

          @end_points_of_contours = io.read(number_of_contours * 2).unpack('n*')
          @instruction_length = io.read(2).unpack1('n')
          @instructions = io.read(instruction_length).unpack('C*')
        end

        def compound?
          false
        end

        def recode(_mapping)
          raw
        end

        def end_point_of_last_contour
          end_points_of_contours.last + 1
        end
      end
    end
  end
end

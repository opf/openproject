# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class Path
        CLOSE_PATH_CMD = [:close].freeze

        attr_reader :commands, :number_of_contours

        def initialize
          @commands = []
          @number_of_contours = 0
        end

        def move_to(x, y)
          @commands << [:move, x, y]
        end

        def line_to(x, y)
          @commands << [:line, x, y]
        end

        def curve_to(x1, y1, x2, y2, x, y)
          @commands << [:curve, x1, y1, x2, y2, x, y]
        end

        def close_path
          @commands << CLOSE_PATH_CMD
          @number_of_contours += 1
        end

        def render(x: 0, y: 0, font_size: 72, units_per_em: 1000)
          new_path = self.class.new
          scale = 1.0 / units_per_em * font_size

          commands.each do |cmd|
            case cmd[:type]
            when :move
              new_path.move_to(x + (cmd[1] * scale), y + (-cmd[2] * scale))
            when :line
              new_path.line_to(x + (cmd[1] * scale), y + (-cmd[2] * scale))
            when :curve
              new_path.curve_to(
                x + (cmd[1] * scale),
                y + (-cmd[2] * scale),
                x + (cmd[3] * scale), y + (-cmd[4] * scale),
                x + (cmd[5] * scale), y + (-cmd[6] * scale)
              )
            when :close
              new_path.close_path
            end
          end

          new_path
        end

        private

        def format_values(command)
          command[1..-1].map { |k| format('%.2f', k) }.join(' ')
        end
      end
    end
  end
end

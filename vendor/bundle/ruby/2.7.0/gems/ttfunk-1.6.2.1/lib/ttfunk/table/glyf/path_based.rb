# frozen_string_literal: true

module TTFunk
  class Table
    class Glyf
      class PathBased
        attr_reader :path, :horizontal_metrics
        attr_reader :x_min, :y_min, :x_max, :y_max
        attr_reader :left_side_bearing, :right_side_bearing

        def initialize(path, horizontal_metrics)
          @path = path
          @horizontal_metrics = horizontal_metrics

          @x_min = 0
          @y_min = 0
          @x_max = horizontal_metrics.advance_width
          @y_max = 0

          path.commands.each do |command|
            cmd, x, y = command
            next if cmd == :close

            @x_min = x if x < @x_min
            @x_max = x if x > @x_max
            @y_min = y if y < @y_min
            @y_max = y if y > @y_max
          end

          @left_side_bearing = horizontal_metrics.left_side_bearing
          @right_side_bearing =
            horizontal_metrics.advance_width -
            @left_side_bearing -
            (@x_max - @x_min)
        end

        def number_of_contours
          path.number_of_contours
        end

        def compound?
          false
        end
      end
    end
  end
end

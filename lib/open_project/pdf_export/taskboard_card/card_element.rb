module OpenProject::PdfExport::TaskboardCard
  class CardElement
    def initialize(pdf, orientation, rows_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @rows_config = rows_config
      @work_package = work_package
      @row_elements = []

      # Initialize row elements
      heights = assign_row_heights
      current_y_offset = 0

      @rows_config["rows"].each_with_index do |(key, value), i|
        current_y_offset += heights[i - 1] if i > 0
        row_orientation = {
          y_offset: @orientation[:height] - current_y_offset,
          x_offset: 0,
          width: @orientation[:width],
          height: heights[i]
        }

        @row_elements << RowElement.new(@pdf, row_orientation, value["columns"], @work_package)
      end
    end

    def assign_row_heights
      # Assign initial heights
      available = @orientation[:height]
      c = @rows_config["rows"].count
      assigned_heights = Array.new(c){available/c}

      min_heights = min_row_heights(c)
      diffs = assigned_heights.zip(min_heights).map {|a, m| a - m}
      diffs.each_with_index do |diff, i|
        if diff < 0
          # Need to grab some pixels from a low priority row and add them to current one
          reduce_low_priority_rows(assigned_heights, diffs, i)
        end
      end

      # TODO: Check assigned heights are big enough
      assigned_heights
    end

    # Return false
    def reduce_low_priority_rows(assigned_heights, diffs, conflicted_i)
      reduce_by = diffs[conflicted_i] * -1
      diffs.each_with_index do |diff, i|
        if diff >= reduce_by
          binding.pry
          assigned_heights[i] -= reduce_by
          assigned_heights[conflicted_i] += reduce_by
          diffs[i] -= reduce_by
          diffs[conflicted_i] += reduce_by
          return true
        end
      end
      return false
    end

    def min_row_heights(c)
      # Calculate minimum user assigned heights...
      min_heights = Array.new(c)
      @rows_config["rows"].each_with_index do |(key, value), i|
        # min lines * font height (first col) # TODO: get the biggest one
        k, v = value["columns"].first
        min_heights[i] = (@pdf.font.height_at(v["font_size"]) * v["minimum_lines"]).floor
      end
      min_heights
    end

    def draw
      top_left = [@orientation[:x_offset], @orientation[:y_offset]]
      bounds = @orientation.slice(:width, :height)

      @pdf.bounding_box(top_left, bounds) do
        @pdf.stroke_color 'FF0000'

        # Draw rows
        @row_elements.each do |row|
          row.draw
        end

        @pdf.stroke_bounds
      end

    end
  end
end
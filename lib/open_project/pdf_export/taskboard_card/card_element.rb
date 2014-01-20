module OpenProject::PdfExport::TaskboardCard
  class CardElement
    include OpenProject::PdfExport::Exceptions

    def initialize(pdf, orientation, rows_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @rows_config = rows_config
      @work_package = work_package
      @row_elements = []
      @rows = @rows_config["rows"]

      raise BadlyFormedTaskboardCardConfigurationError.new("Badly formed YAML") if @rows.nil?

      # Simpler to remove empty rows before calculating the row sizes
      RowElement.prune_empty_rows(@rows, work_package)

      heights = assign_row_heights
      current_y_offset = 0

      @rows.each_with_index do |(key, value), i|
        current_y_offset += heights[i - 1] if i > 0
        row_orientation = {
          y_offset: @orientation[:height] - current_y_offset,
          x_offset: 0,
          width: @orientation[:width],
          height: heights[i]
        }

        @row_elements << RowElement.new(@pdf, row_orientation, value, @work_package)
      end
    end

    def assign_row_heights
      # Assign initial heights
      available = @orientation[:height]
      c = @rows.count
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

    def reduce_low_priority_rows(assigned_heights, diffs, conflicted_i)
      # Get an array of row indexes sorted by inverse priority
      priorities = *(0..@rows_config["rows"].count - 1)
        .zip(@rows_config["rows"].map { |k, v| first_column_property(v, "priority") or 10 })
        .sort {|x,y| y[1] <=> x[1]}
        .map {|x| x[0]}

      to_reduce = diffs[conflicted_i] * -1
      priorities.each do |p|
        diff = diffs[p]
        if diff > 0
          if diff >= to_reduce
            exchange(assigned_heights, diffs, p, conflicted_i, to_reduce)
            return true
          else
            exchange(assigned_heights, diffs, p, conflicted_i, diff)
            to_reduce -= diff
          end
        end
      end
      return false
    end

    def first_column_property(row_hash, property)
      k, v = row_hash["columns"].first
      v[property]
    end

    def exchange(heights, diffs, a, b, v)
      heights[a] -= v
      heights[b] += v
      diffs[a] -= v
      diffs[b] += v
    end

    def min_row_heights(c)
      # Calculate minimum user assigned heights...
      min_heights = Array.new(c)
      @rows_config["rows"].each_with_index do |(key, value), i|
        # min lines * font height (first col) # TODO: get the biggest one
        k, v = value["columns"].first
        min_lines = v["minimum_lines"]
        min_lines ||= 1
        font_size = v["font_size"]
        font_size ||= 10
        min_heights[i] = (@pdf.font.height_at(font_size) * min_lines).floor
      end
      min_heights
    end

    def draw
      top_left = [@orientation[:x_offset], @orientation[:y_offset]]
      bounds = @orientation.slice(:width, :height)

      @pdf.bounding_box(top_left, bounds) do
        @pdf.stroke_color '000000'

        # Draw rows
        @row_elements.each do |row|
          row.draw
        end

        @pdf.stroke_bounds
      end

    end
  end
end
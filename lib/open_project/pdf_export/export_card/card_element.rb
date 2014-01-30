module OpenProject::PdfExport::ExportCard
  class CardElement
    include OpenProject::PdfExport::Exceptions

    def initialize(pdf, orientation, groups_config, work_package)
      @pdf = pdf
      @orientation = orientation
      # @rows_config = rows_config
      @groups_config = groups_config
      @work_package = work_package
      @group_elements = []
      # TODO: This is redundant, the has should just be the rows
      #       OR if we're going to have boxed groups then this is where they'd be
      # @groups = @rows_config["rows"]

      # raise BadlyFormedExportCardConfigurationError.new("Badly formed YAML") if @rows.nil?

      # Simpler to remove empty rows before calculating the row sizes
      RowElement.prune_empty_groups(@groups_config, work_package)

      # Get an array of all the row hashes
      rows = []
      @groups_config.each do |gk, gv|
        gv["rows"].each do |rk, rv|
          rows << rv
        end
      end

      # Assign the row height, ignoring groups
      heights = assign_row_heights(rows)

      text_padding = @orientation[:text_padding]
      group_padding = @orientation[:group_padding]
      current_row = 0
      current_y_offset = text_padding

      # Initialize groups
      @groups_config.each_with_index do |(g_key, g_value), i|
        row_count = g_value["rows"].count
        row_heights = heights.slice(current_row, row_count)
        group_height = row_heights.sum
        group_orientation = {
          y_offset: @orientation[:height] - current_y_offset,
          x_offset: 0,
          width: @orientation[:width],
          height: group_height,
          row_heights: row_heights,
          text_padding: text_padding,
          group_padding: group_padding
        }
        @group_elements << GroupElement.new(@pdf, group_orientation, g_value, @work_package)

        current_y_offset += group_height
        current_row += row_count
      end
    end

    def assign_row_heights(rows)
      # Assign initial heights for rows in all groups
      available = @orientation[:height] - @orientation[:text_padding]
      c = rows.count
      assigned_heights = Array.new(c){ available / c }

      min_heights = min_row_heights(rows)
      diffs = assigned_heights.zip(min_heights).map {|a, m| a - m}
      diffs.each_with_index do |diff, i|
        if diff < 0
          # Need to grab some pixels from a low priority row and add them to current one
          reduce_low_priority_rows(rows, assigned_heights, diffs, i)
        end
      end

      # TODO: Check assigned heights are big enough
      assigned_heights
    end

    def reduce_low_priority_rows(rows, assigned_heights, diffs, conflicted_i)
      # Get an array of row indexes sorted by inverse priority
      priorities = *(0..rows.count - 1)
        .zip(rows.map { |k, v| v["priority"] or 10 })
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

    def min_row_heights(rows)
      # Calculate minimum user assigned heights...
      min_heights = Array.new(rows.count)
      rows.each_with_index do |row, i|
        # min lines * font height (first col) # TODO: get the biggest one
        k, v = row["columns"].first
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
        @group_elements.each do |group|
          group.draw
        end

        @pdf.stroke_bounds
      end

    end
  end
end
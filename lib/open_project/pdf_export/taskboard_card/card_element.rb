module OpenProject::PdfExport::TaskboardCard
  class CardElement
    def initialize(pdf, orientation, rows_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @rows_config = rows_config
      @work_package = work_package
      @row_elements = []

      # Initialize row elements
      row_y_offset = 0
      rows_config["rows"].each do |key, value|
        # TODO: Intelligently configure the orientation of row elements
        row_orientation = {
          y_offset: @orientation[:height] - row_y_offset,
          x_offset: 0,
          width: 400, # TODO: Calculate
          height: 40 # TODO: Calculate
        }
        row_y_offset += 40 # TODO: Calculate from text size, lines, priority, whatever

        @row_elements << RowElement.new(@pdf, row_orientation, value["columns"], @work_package)
      end
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
module OpenProject::PdfExport::TaskboardCard
  class RowElement
    def initialize(pdf, orientation, columns_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @columns_config = columns_config
      @work_package = work_package
      @column_elements = []

      # Initialise column elements
      x_offset = 0

      columns_config.each_with_index do |key, value|
        width = col_width(value)
        column_orientation = @orientation.clone
        column_orientation[:x_offset] = x_offset
        column_orientation[:width] = width
        x_offset += width

        @column_elements << ColumnElement.new(@pdf, key, value, column_orientation, @work_package)
      end
    end

    def col_width(col_config)
      cols_count = @columns_config.count
      w = col_config["width"]
      return @orientation[:width] / cols_count if w.nil?

      i = w.index("%") or w.length
      Float(w.slice(0, i)) / 100 * @orientation[:width]
    end

    def draw
      # Draw columns
      @column_elements.each do |c|
        c.draw
      end
    end
  end
end
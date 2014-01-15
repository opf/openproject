module OpenProject::PdfExport::TaskboardCard
  class RowElement
    def initialize(pdf, orientation, columns_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @columns_config = columns_config
      @work_package = work_package
      @column_elements = []

      # Initialise column elements
      column_position = 0
      cols_count = columns_config.count
      default_col_width = @orientation[:width] / cols_count

      columns_config.each do |key, value|
        # TODO: Intelligently configure the orientation of column elements
        column_orientation = @orientation.clone
        column_orientation[:x_offset] = column_position * default_col_width
        column_orientation[:width] = default_col_width

        @column_elements << ColumnElement.new(@pdf, key, value, column_orientation, @work_package)
        column_position += 1
      end
    end

    def draw
      # Draw columns
      @column_elements.each do |c|
        c.draw
      end
    end
  end
end
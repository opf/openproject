module OpenProject::PdfExport::TaskboardCard
  class RowElement
    def initialize(pdf, orientation, columns_config, work_package)
      @pdf = pdf
      @orientation = orientation
      @columns_config = columns_config
      @work_package = work_package
      @column_elements = []

      # Initialise column elements
      columns_config.each do |key, value|
        # TODO: Intelligently configure the orientation of column elements
        column_orientation = @orientation
        @column_elements << ColumnElement.new(@pdf, key, value, column_orientation, @work_package)
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
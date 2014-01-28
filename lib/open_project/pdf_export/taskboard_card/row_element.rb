module OpenProject::PdfExport::TaskboardCard
  class RowElement
    include OpenProject::PdfExport::Exceptions

    def initialize(pdf, orientation, config, work_package)
      @pdf = pdf
      @orientation = orientation
      @config = config
      @columns_config = config["columns"]
      @work_package = work_package
      @column_elements = []

      raise BadlyFormedTaskboardCardConfigurationError.new("Badly formed YAML") if @columns_config.nil?

      # Initialise column elements
      x_offset = 0
      padding = @orientation[:text_padding]

      @columns_config.each do |key, value|
        width = col_width(value) - padding
        column_orientation = @orientation.clone
        column_orientation[:x_offset] = x_offset + padding
        column_orientation[:width] = width - padding
        x_offset += width + padding

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
      top_left = [@orientation[:x_offset], @orientation[:y_offset]]
      bounds = @orientation.slice(:width, :height)
      @pdf.bounding_box(top_left, bounds) do
        if @config["has_border"]
          @pdf.stroke_bounds
        end

        # Draw columns
        @column_elements.each do |c|
          c.draw
        end
      end

    end

    def self.prune_empty_rows(rows, wp)
      rows.each_with_index do |(rk, rv), i|
        ck, cv = rv["columns"].first
        if is_empty_column(ck, cv, wp)
          rows.delete(rk)
        end
      end
    end

    def self.is_empty_column(property_name, column, wp)
      value = wp.send(property_name) if wp.respond_to?(property_name) else ""
      value = "" if value.is_a?(Array) && value.empty?
      value = value.to_s if !value.is_a?(String)
      !column["render_if_empty"] && value.empty?
    end
  end
end
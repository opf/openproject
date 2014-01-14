require 'prawn'

module OpenProject::PdfExport::TaskboardCard
  class DocumentGenerator
    attr_reader :config
    attr_reader :work_packages
    attr_reader :pdf
    attr_reader :current_position

    def initialize(config, work_packages)
      defaults = { page_size: "A4" }

      @config = config
      @work_packages = work_packages

      page_layout = :landscape
      page_size = config.page_size or defaults[:page_size]

      @pdf = Prawn::Document.new(
        :page_layout => page_layout,
        :left_margin => 0,
        :right_margin => 0,
        :top_margin => 0,
        :bottom_margin => 0,
        :page_size => page_size)
    end

    def render
      # TODO RS: Define pdf page defaults, sizes, borders etc...
      # pdf.start_new_page
      render_cards

      pdf.render
    end

    def render_cards
      # TESTING: RENDER FIRST WORK PACKAGE
      render_rows(work_packages.first)

      # TODO: Removed for testing convenience
      # Iterate over all work packages
      # work_packages.each_with_index do |wp, i|
      #   render_rows wp
      # end
    end

    def render_rows(work_package)
      @current_position = {
        y_offset: pdf.bounds.height,
        x_offset: 0
      }

      config.rows_hash["rows"].each do |key, value|
        render_row(work_package, value)
        adjust_current_position(value)
      end
    end

    def render_row(work_package, row_hash)
      row_hash["columns"].each do |key, value|
        render_column(work_package, key, value)
      end
    end

    def render_column(work_package, property_name, column_hash)
      column = ColumnElement.new(pdf, work_package, property_name, column_hash)
      column.draw(current_position)
    end

    def adjust_current_position(row_config)
        # The current position needs to be manipulated based on the minimun lines, font size and
        # priority of the column. This will need to take into consideration all of the rows at once
        # to decide on which ones get prioritised, and so will need something a lot more clever
        # than just adjusting it inline like this.
        current_position[:y_offset] -= (pdf.bounds.height * 0.05)
    end
  end

  class ColumnElement
    def initialize(pdf, work_package, property_name, config)
      @pdf = pdf
      @work_package = work_package
      @property_name = property_name
      @config = config
    end

    def draw(position)
      # Get value from model
      has_label = @config['has_label']

      value = @work_package.send(@property_name) if @work_package.respond_to?(@property_name)
      value = value.to_s

      text = ""
      text = text + "#{@property_name}:- " if has_label
      text = text + value

      # Draw on pdf
      offset = [0, position[:y_offset]]
      box = @pdf.text_box(text,
        {:height => 20,
         :at => offset,
         :size => 20,
         :padding_bottom => 5})
    end
  end
end
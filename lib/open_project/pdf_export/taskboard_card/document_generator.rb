require 'prawn'

module OpenProject::PdfExport::TaskboardCard
  class DocumentGenerator

    attr_reader :config
    attr_reader :work_packages
    attr_reader :pdf
    attr_reader :current_position
    attr_reader :paper_width
    attr_reader :paper_height

    def initialize(config, work_packages)
      defaults = { page_size: "A4" }

      @config = config
      @work_packages = work_packages

      page_layout = :landscape
      page_size = config.page_size or defaults[:page_size]
      geom = Prawn::Document::PageGeometry::SIZES[page_size]
      @paper_width = geom[0]
      @paper_height = geom[1]

      @pdf = Prawn::Document.new(
        :page_layout => page_layout,
        :left_margin => 0,
        :right_margin => 0,
        :top_margin => 0,
        :bottom_margin => 0,
        :page_size => page_size)
    end

    def render
      render_pages
      pdf.render
    end

    def render_pages
      @work_packages.each do |wp|
        @config.per_page.times do
          # Position and size depend on how the cards are to be arranged on the page which is not known yet
          padding = 20

          orientation = {
            y_offset: pdf.bounds.height - padding,
            x_offset: padding,
            width: 400,
            height: 400
          }

          card_element = CardElement.new(pdf, orientation, config.rows_hash, wp)
          card_element.draw
        end
        pdf.start_new_page
      end
    end
  end
end
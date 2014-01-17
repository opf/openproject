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

      page_layout = :landscape if config.landscape? else :portrait
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
      padding = 10
      card_width = 400
      card_height = ((pdf.bounds.height - (padding * @config.per_page )) / @config.per_page) - (padding / @config.per_page)
      card_y_offset = pdf.bounds.height - padding

      @work_packages.each_with_index do |wp, i|
        orientation = {
          y_offset: card_y_offset,
          x_offset: padding,
          width: card_width,
          height: card_height
        }

        card_element = CardElement.new(pdf, orientation, config.rows_hash, wp)
        if i > 0 && i % @config.per_page == 0
          pdf.start_new_page
        end
        card_element.draw

        if (i + 1) % @config.per_page == 0
          card_y_offset = pdf.bounds.height - padding
        else
          card_y_offset -= (card_height + padding)
        end
      end
    end
  end
end
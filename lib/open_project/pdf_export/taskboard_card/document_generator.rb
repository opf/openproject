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
      card_padding = 10
      text_padding = 5
      card_width = pdf.bounds.width - (card_padding * 2)
      card_height = ((pdf.bounds.height - (card_padding * config.per_page )) / config.per_page) - (card_padding / config.per_page)
      card_y_offset = pdf.bounds.height - card_padding

      @work_packages.each_with_index do |wp, i|
        orientation = {
          y_offset: card_y_offset,
          x_offset: card_padding,
          width: card_width,
          height: card_height,
          card_padding: card_padding,
          text_padding: text_padding
        }

        card_element = CardElement.new(pdf, orientation, config.rows_hash, wp)
        if i > 0 && i % config.per_page == 0
          pdf.start_new_page
        end
        card_element.draw

        if (i + 1) % config.per_page == 0
          card_y_offset = pdf.bounds.height - card_padding
        else
          card_y_offset -= (card_height + card_padding)
        end
      end
    end
  end
end
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
      # TODO RS: Define pdf page defaults, sizes, borders etc...
      # pdf.start_new_page
      render_cards
      pdf.render
    end

    def render_cards

      # TODO: This needs to be done for x cards per page and the appropriate offsets and bounds
      # calculated for each. Just now doing the default 1 per page and only the first work package.
      orientation = {
        y_offset: pdf.bounds.height - 20,
        x_offset: 20,
        width: 400, # TODO: Calculate these based on page layout
        height: 400
      }

      card_element = CardElement.new(pdf, orientation, config.rows_hash, work_packages.first)
      card_element.draw
    end

    # def to_pts(v)
    #   return if v.nil?
    #   if v =~ /[a-z]{2}$/i
    #     units = v[-2, 2].downcase
    #     v = v[0..-3]
    #   else
    #     units = 'pt'
    #   end

    #   v = "#{v}0" if v =~ /\.$/

    #   return Float(v).mm if units == 'mm'
    #   return Float(v).cm if units == 'cm'
    #   return Float(v).in if units == 'in'
    #   return Float(v).pt if units == 'pt'
    #   raise "Unexpected units '#{units}'"
    # end
  end

end
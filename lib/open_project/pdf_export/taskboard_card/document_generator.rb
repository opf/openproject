require 'prawn'

module OpenProject::PdfExport::TaskboardCard
  class DocumentGenerator
    attr_reader :config
    attr_reader :work_packages
    attr_reader :pdf

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
      render_rows

      pdf.render
    end

    def render_rows
      # TESTING: RENDER FIRST WORK PACKAGE
      wp = work_packages.first
      work_package_identification = "#{wp.type.name} ##{wp.id}"
      offset = [0, pdf.bounds.height]
      box = pdf.text_box(work_package_identification,
        {:height => 20,
         :at => offset,
         :size => 20,
         :padding_bottom => 5})

      # TODO RS: Iterate over each row and render whatever specified
      # work_packages.each_with_index do |wp, i|
      #   config.rows_hash.each do |key, value|
      #     render_row(wp, value)
      #   end
      # end
    end

    def render_row(work_package, row_hash)
      row_hash.columns.each do |key, value|
        render_column(value)
      end
    end

    def render_column(column_hash)
      # Do actual pdf rendering
    end
  end
end
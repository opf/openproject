# frozen_string_literal: true

require "csv"

module TestManagement
  module Exports
    # Shared plumbing for the test management exports (PDF, CSV, Excel).
    #
    # Builds on OpenProject's ::Exports::Exporter (user, sane file names) and
    # returns an ::Exports::Result like the work package exports, but renders
    # synchronously: the controller streams the result with send_data.
    #
    # Subclasses provide:
    #   #title           -> String (also the file name stem)
    #   #headers         -> [String]
    #   #rows            -> [[String]] (flat, for CSV and Excel)
    #   #preamble        -> [[label, value]] printed above the table (may be empty)
    #   #render_pdf(pdf) -> draws the PDF body on a Prawn document
    class BaseExporter < ::Exports::Exporter
      FORMATS = %w[pdf csv xls].freeze
      MIME_TYPES = {
        "pdf" => "application/pdf",
        "csv" => "text/csv",
        "xls" => "application/vnd.ms-excel"
      }.freeze
      LIST_SEPARATOR = "; "

      def self.valid_format?(format)
        FORMATS.include?(format.to_s)
      end

      def format
        options.fetch(:format).to_s
      end

      def export!
        raise ArgumentError, "Unknown export format #{format.inspect}" unless self.class.valid_format?(format)

        content = public_send(:"to_#{format}")
        ::Exports::Result.new(format: format.to_sym,
                              title: filename,
                              content:,
                              mime_type: MIME_TYPES.fetch(format))
      end

      def filename
        sane_filename("#{title} #{Time.zone.today.iso8601}.#{format}")
      end

      def preamble
        []
      end

      # --- CSV ---------------------------------------------------------------
      def to_csv
        serialized = ::CSV.generate(col_sep: csv_separator) do |csv|
          if preamble.any?
            csv << csv_cells([title])
            preamble.each { |label, value| csv << csv_cells([label, value]) }
            csv << []
          end
          csv << csv_cells(csv_headers)
          rows.each { |row| csv << csv_cells(row) }
        end
        # UTF-8 BOM so Excel detects the encoding, as in OpenProject's CSV exports.
        "\xEF\xBB\xBF#{serialized}"
      end

      # --- Excel (.xls, via the spreadsheet gem used by OpenProject's XLS export)
      def to_xls
        require "spreadsheet"

        book = ::Spreadsheet::Workbook.new
        sheet = book.create_worksheet(name: sheet_name)
        bold = ::Spreadsheet::Format.new(weight: :bold)
        heading = ::Spreadsheet::Format.new(weight: :bold, size: 14)
        wrap = ::Spreadsheet::Format.new(text_wrap: true, vertical_align: :top)

        index = 0
        sheet.row(index).replace([title])
        sheet.row(index).set_format(0, heading)
        index += 1
        preamble.each do |label, value|
          sheet.row(index).replace([label, value.to_s])
          sheet.row(index).set_format(0, bold)
          index += 1
        end
        index += 1

        sheet.row(index).replace(headers)
        headers.each_index { |col| sheet.row(index).set_format(col, bold) }
        rows.each do |row|
          index += 1
          sheet.row(index).replace(row.map { |cell| xls_cell(cell) })
          row.each_index { |col| sheet.row(index).set_format(col, wrap) }
        end
        column_widths.each_with_index { |width, col| sheet.column(col).width = width }

        io = StringIO.new
        book.write(io)
        io.string
      end

      # --- PDF ---------------------------------------------------------------
      def to_pdf
        require "prawn"
        require "prawn/table"

        pdf = pdf_document
        pdf.text title, size: 16, style: :bold
        pdf.move_down 2
        pdf.text generated_line, size: 8, color: "57606A"
        pdf.move_down 10
        render_pdf(pdf)
        pdf_page_numbers(pdf)
        pdf.render
      end

      protected

      def sheet_name
        title.gsub(%r{[\[\]*?:/\\]}, " ").strip.first(31)
      end

      # Relative widths for the Excel columns (characters); subclasses tune them.
      def column_widths
        headers.map { 18 }
      end

      def csv_headers
        list = headers.dup
        # Excel treats a CSV starting with "ID" as SYLK, as OpenProject's CSV export notes.
        list[0] = list[0].downcase if list.first&.start_with?("ID")
        list
      end

      def csv_cells(cells)
        cells.map do |cell|
          value = cell.to_s
          if defined?(::Exports::Concerns::CSVFormulaSanitization)
            value = ::Exports::Concerns::CSVFormulaSanitization.sanitize(value)
          end
          value
        end
      end

      def csv_separator
        separator = I18n.t(:general_csv_separator, default: ",")
        separator.presence || ","
      end

      def xls_cell(cell)
        cell.nil? ? "" : cell
      end

      # Prawn document using OpenProject's PDF fonts (Noto with fallbacks, so any
      # script renders), landscape A4.
      def pdf_document
        if defined?(::Exports::PDF::Common::View)
          view = ::Exports::PDF::Common::View.new(current_language)
          view.options.merge!(page_size: "A4", page_layout: :landscape, margin: 36)
          view.title = title
          view.document
        else
          ::Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: 36, info: { Title: title })
        end
      end

      def pdf_page_numbers(pdf)
        pdf.number_pages "<page>/<total>", at: [pdf.bounds.right - 60, -10], width: 60, align: :right, size: 8
      end

      def pdf_heading(pdf, text, size: 12)
        pdf.move_down 8
        pdf.text text, size:, style: :bold
        pdf.move_down 4
      end

      def pdf_key_values(pdf, pairs)
        return if pairs.empty?

        data = pairs.map { |label, value| [{ content: label.to_s, font_style: :bold }, value.to_s] }
        pdf.table(data, cell_style: { size: 9, borders: [], padding: [2, 8, 2, 0] })
      end

      def pdf_table(pdf, header, data, widths: nil, &block)
        table_options = {
          header: true,
          width: pdf.bounds.width,
          cell_style: { size: 8, padding: 4, border_color: "D0D7DE", inline_format: false }
        }
        table_options[:column_widths] = widths if widths
        pdf.table([header] + data, table_options) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = "F6F8FA"
          block&.call(table)
        end
      end

      def generated_line
        I18n.t("test_management.exports.generated",
               user: current_user.name,
               time: format_time(Time.current))
      end

      def user_name(user)
        user&.name.to_s
      end

      def time_value(time)
        time ? format_time(time) : ""
      end

      def yes_no(value)
        I18n.t(value ? :general_text_Yes : :general_text_No)
      end

      # "Parent / Child" for every folder of the project, from one query.
      def folder_paths(project)
        suites = TestManagement::Suite.where(project_id: project.id).pluck(:id, :parent_id, :name)
        by_id = suites.to_h { |id, parent_id, name| [id, [parent_id, name]] }
        by_id.keys.index_with do |id|
          names = []
          seen = []
          while id && by_id[id] && seen.exclude?(id)
            seen << id
            names.unshift(by_id[id].last)
            id = by_id[id].first
          end
          names.join(" / ")
        end
      end

      def unfiled_label
        I18n.t("test_management.suites.unfiled")
      end
    end
  end
end

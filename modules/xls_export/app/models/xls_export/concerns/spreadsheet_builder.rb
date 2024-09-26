module XlsExport
  module Concerns
    module SpreadsheetBuilder
      def records
        raise NotImplementedError
      end

      def spreadsheet_title
        raise NotImplementedError
      end

      def export!
        success(spreadsheet.xls)
      end

      def success(content)
        ::Exports::Result
          .new format: :xls,
               content:,
               title: xls_export_filename,
               mime_type: "application/vnd.ms-excel"
      end

      def spreadsheet
        sb = spreadsheet_builder

        add_headers! sb
        add_rows! sb
        set_column_format_options! sb

        sb
      end

      def add_headers!(spreadsheet)
        spreadsheet.add_headers headers, 0
      end

      def add_rows!(spreadsheet)
        rows.each do |row|
          spreadsheet.add_row row
        end
      end

      def rows
        records.map do |object|
          row object
        end
      end

      # Forwards to column_values by default
      # but allows for extensions
      def row(object)
        column_values(object)
      end

      def column_values(object)
        columns.collect do |column|
          format_attribute(object, column[:name], :csv)
        end
      end

      def set_column_format_options!(spreadsheet)
        columns.each_with_index do |column, i|
          options = formatter_for(column[:name], :csv)
                      .format_options

          spreadsheet.add_format_option_to_column i, options
        end
      end

      def spreadsheet_builder
        OpenProject::XlsExport::SpreadsheetBuilder.new spreadsheet_title
      end

      def headers
        columns.pluck(:caption)
      end

      def xls_export_filename
        sane_filename(
          "#{Setting.app_title} #{spreadsheet_title} \
          #{format_time_as_date(Time.zone.now, format: '%Y-%m-%d')}.xls"
        )
      end
    end
  end
end

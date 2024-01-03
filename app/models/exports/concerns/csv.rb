#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Exports
  module Concerns
    module CSV
      def export!
        serialized = ::CSV.generate(col_sep: I18n.t(:general_csv_separator)) do |csv|
          headers = csv_headers
          csv << encode_csv_columns(headers)

          records.each do |record|
            row = csv_row(record)
            csv << encode_csv_columns(row)
          end
        end

        success(serialized)
      end

      def encode_csv_columns(columns, encoding = I18n.t(:general_csv_encoding))
        columns.map do |cell|
          Redmine::CodesetUtil.from_utf8(cell.to_s, encoding)
        end
      end

      def success(serialized)
        ::Exports::Result
          .new format: :csv,
               title: csv_export_filename,
               content: serialized,
               mime_type: 'text/csv'
      end

      # fetch all headers
      def csv_headers
        headers = columns.pluck(:caption)

        # because of
        # https://support.microsoft.com/en-us/help/323626/-sylk-file-format-is-not-valid-error-message-when-you-open-file
        if headers[0].start_with?('ID')
          headers[0] = headers[0].downcase
        end

        headers
      end

      # fetch all row values
      def csv_row(record)
        columns.collect do |column|
          format_csv(record, column[:name])
        end
      end

      def format_csv(record, attribute)
        format_attribute(record, attribute, :csv, array_separator: '; ')
      end

      def csv_export_filename
        sane_filename(
          "#{Setting.app_title} #{title} \
          #{format_time_as_date(Time.zone.now, '%Y-%m-%d')}.csv"
        )
      end
    end
  end
end

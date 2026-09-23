# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Import
    module CSV
      class Parser
        # Excel writes ; on a German locale and \t when saving as "Unicode text".
        SEPARATORS = %W[, ; \t].freeze

        Row = Data.define(:number, :values, :problems)

        def self.call(file) = new(file).call

        def initialize(file)
          @file = file
        end

        # @return [ServiceResult] success carries an array of Row, failure an array of
        #   HeaderMap::Problem
        def call
          problems = header_problems
          return ServiceResult.failure(result: problems) if problems.any?

          rows = read_rows
          return ServiceResult.failure(result: [file_problem(:no_rows)]) if rows.empty?
          return ServiceResult.failure(result: [too_many_rows]) if rows.size > max_rows

          ServiceResult.success(result: rows)
        rescue ::CSV::InvalidEncodingError => e
          ServiceResult.failure(result: [file_problem(:invalid_encoding, line: e.line_number)])
        end

        def separator
          @separator ||= SEPARATORS.max_by { |candidate| [resolvable_headers(candidate), -SEPARATORS.index(candidate)] }
        end

        private

        attr_reader :file

        def path = file.respond_to?(:path) ? file.path : file.to_s

        def max_rows = @max_rows ||= Setting.work_package_import_max_rows

        def header_map = @header_map ||= HeaderMap.new

        def headers = header_entry(separator).first

        def header_index = header_entry(separator).last

        def header_entry(candidate)
          @header_entries ||= {}
          @header_entries[candidate] ||= first_populated_row(candidate)
        end

        def first_populated_row(candidate)
          values, index = ::CSV.foreach(path, encoding: "bom|utf-8", col_sep: candidate)
                               .with_index
                               .find { |row, _| row.any?(&:present?) } || [[], 0]

          [values.reverse.drop_while(&:blank?).reverse, index]
        end

        def resolvable_headers(candidate)
          header_entry(candidate).first.count { |header| header_map.resolve(header) }
        rescue ::CSV::MalformedCSVError
          0
        end

        def header_result = @header_result ||= header_map.call(headers)

        def header_problems
          return [file_problem(:empty)] if headers.empty?

          (header_result.success? ? [] : header_result.result) + setting_problems
        end

        # The header rules that depends on configuration rather than the file.
        def setting_problems
          return [] unless WorkPackage.status_based_mode?

          derived_headers.map do |attribute|
            HeaderMap::Problem.new(column: nil,
                                   header: WorkPackage.human_attribute_name(attribute),
                                   message: I18n.t("work_packages.import.csv.header.status_based"))
          end
        end

        def derived_headers
          headers.filter_map { |header| header_map.resolve(header) } & HeaderMap::DERIVED_FROM_STATUS
        end

        def read_rows
          rows = []

          ::CSV.foreach(path, encoding: "bom|utf-8", col_sep: separator).with_index do |values, index|
            next if index <= header_index
            next if values.all?(&:blank?)

            rows << Row.new(number: index + 1, values: attributes_for(values), problems: problems_for(values))
            break if rows.size > max_rows
          end

          rows
        end

        def attributes_for(values)
          mapping.to_h { |attribute, index| [attribute, values[index]] }
        end

        # Cells past the last header are dropped, which is silent data loss when they
        # hold anything. The usual cause is a separator inside an unquoted value.
        def problems_for(values)
          extra = values.drop(headers.size)
          return [] if extra.all?(&:blank?)

          [I18n.t("work_packages.import.csv.row.too_many_cells",
                  count: values.size, expected: headers.size)]
        end

        def mapping = header_result.result

        def file_problem(key, **)
          HeaderMap::Problem.new(column: nil, header: nil,
                                 message: I18n.t("work_packages.import.csv.file.#{key}", **))
        end

        def too_many_rows
          HeaderMap::Problem.new(column: nil, header: nil,
                                 message: I18n.t("work_packages.import.csv.file.too_many_rows",
                                                 limit: max_rows))
        end
      end
    end
  end
end

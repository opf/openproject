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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module Import
    module CSV
      # Finds the header row of a CSV and the separator it was written with, by reading the first
      # populated row with each candidate and counting the headers a HeaderMap recognises.
      class HeaderSniffer
        # Excel writes ; on a German locale and \t when saving as "Unicode text".
        SEPARATORS = %W[, ; \t].freeze

        Header = Data.define(:separator, :values, :index)

        def self.call(path, header_map) = new(path, header_map).call

        def initialize(path, header_map)
          @path = path
          @header_map = header_map
        end

        # @return [Header] the separator, the header row with its trailing blanks dropped, and the
        #   line it sits on
        def call
          values, index = entry(separator)

          Header.new(separator:, values:, index:)
        end

        private

        attr_reader :path, :header_map

        # A tie goes to the earliest candidate, which is why the index is negated.
        def separator
          SEPARATORS.max_by { |candidate| [resolvable_headers(candidate), -SEPARATORS.index(candidate)] }
        end

        def resolvable_headers(candidate)
          entry(candidate).first.count { |header| header_map.resolve(header) }
        rescue ::CSV::MalformedCSVError
          0
        end

        def entry(candidate)
          @entries ||= {}
          @entries[candidate] ||= first_populated_row(candidate)
        end

        def first_populated_row(candidate)
          values, index = ::CSV.foreach(path, encoding: "bom|utf-8", col_sep: candidate)
                               .with_index
                               .find { |row, _| row.any?(&:present?) } || [[], 0]

          [values.reverse.drop_while(&:blank?).reverse, index]
        end
      end
    end
  end
end

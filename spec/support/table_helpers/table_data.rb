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

module TableHelpers
  # Contains work packages information from a table representation.
  class TableData
    extend Identifier

    attr_reader :work_packages_data

    def self.for(representation)
      work_packages_data = TableParser.new.parse(representation)
      TableData.new(work_packages_data)
    end

    def self.from_work_packages(work_packages, columns)
      work_packages_data = work_packages.map do |work_package|
        attributes = columns.reduce({}) do |attrs, column|
          attrs.merge!(column.attributes_for_work_package(work_package))
        end
        row = columns.to_h { [_1.title, nil] }
        identifier = to_identifier(work_package.subject)
        {
          attributes:,
          row:,
          identifier:
        }
      end
      TableData.new(work_packages_data)
    end

    def initialize(work_packages_data)
      @work_packages_data = work_packages_data
    end

    def columns
      headers.map do |header|
        Column.for(header)
      end
    end

    def headers
      work_packages_data.first[:row].keys
    end

    def values_for_attribute(attribute)
      work_packages_data.map do |work_package_data|
        work_package_data.dig(:attributes, attribute)
      end
    end

    def work_package_identifiers
      work_packages_data.pluck(:identifier)
    end

    def create_work_packages
      work_packages_by_identifier = Factory.new(self).create
      Table.new(work_packages_by_identifier)
    end

    def order_like!(other_table)
      ordered_identifiers = other_table.work_package_identifiers
      extra_identifiers = work_package_identifiers - ordered_identifiers
      @work_packages_data = work_packages_data
        .index_by { _1[:identifier] }
        .values_at(*(ordered_identifiers + extra_identifiers))
        .compact
    end

    class Factory
      attr_reader :table_data, :work_packages_by_identifier

      def initialize(table_data)
        @table_data = table_data
        @work_packages_by_identifier = {}
      end

      def create
        table_data.work_package_identifiers.map do |identifier|
          create_work_package(identifier)
        end
        work_packages_by_identifier
      end

      def create_work_package(identifier)
        @work_packages_by_identifier[identifier] ||= begin
          attributes = work_package_attributes(identifier)
          attributes[:parent] = lookup_parent(attributes[:parent])
          if status = lookup_status(attributes[:status])
            attributes[:status] = status
          end
          FactoryBot.create(:work_package, attributes)
        end
      end

      def lookup_parent(identifier)
        if identifier
          @work_packages_by_identifier[identifier] || create_work_package(identifier)
        end
      end

      def lookup_status(status_name)
        if status_name
          statuses_by_name.fetch(status_name) do
            raise NameError, "No status with name \"#{status_name}\" found. " \
                             "Available statuses are: #{statuses_by_name.keys}."
          end
        end
      end

      def statuses_by_name
        @statuses_by_name ||= Status.all.index_by(&:name)
      end

      def work_package_attributes(identifier)
        data = table_data.work_packages_data.find { |wpa| wpa[:identifier] == identifier.to_sym }
        data[:attributes]
      end
    end
  end
end

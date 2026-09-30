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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
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
        row = columns.to_h { [it.title, nil] }
        identifier = Registry.find_identifier(work_package) || to_identifier(work_package.subject)
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
      work_packages_by_identifier, relations = Factory.new(self).create
      Registry.store(work_packages_by_identifier)
      Table.new(work_packages_by_identifier, relations)
    end

    def hierarchy_levels
      identifiers = work_packages_data.pluck(:identifier)
      parents = work_packages_data.pluck(:attributes).pluck(:parent)
      identifier_parent_tuples = identifiers.zip(parents)
      levels = {}
      iterations = 0
      while identifier_parent_tuples.any? && iterations < identifier_parent_tuples.size
        identifier, parent = identifier_parent_tuples.shift
        if parent.nil?
          levels[identifier] = 0
          iterations = 0
        elsif levels.has_key?(parent)
          levels[identifier] = levels[parent] + 1
          iterations = 0
        else
          identifier_parent_tuples.push([identifier, parent])
          iterations += 1
        end
      end
      levels
    end

    def children_by_parent(parent_identifier)
      work_packages_data
        .filter { it.dig(:attributes, :parent) == parent_identifier }
        .pluck(:identifier)
    end

    def order_like!(other_table)
      @work_packages_data = work_packages_data
        .index_by { it[:identifier] }
        .values_at(*identifiers_ordered_like(other_table))
        .compact
    end

    def identifiers_ordered_like(other_table, parent_identifier = nil, acc = [])
      other_children = other_table.children_by_parent(parent_identifier)
      own_children = children_by_parent(parent_identifier)
      ordered_children = other_children.intersection(own_children) + own_children.difference(other_children)
      ordered_children.each do |identifier|
        acc << identifier
        identifiers_ordered_like(other_table, identifier, acc)
      end
      acc
    end

    class Registry
      class << self
        def store(work_packages_by_identifier)
          work_packages_by_identifier.each do |identifier, work_package|
            identifiers_by_work_package_id[work_package.id] = identifier
          end
        end

        def find_identifier(work_package)
          identifiers_by_work_package_id[work_package.id]
        end

        def identifiers_by_work_package_id
          @identifiers_by_work_package_id ||= {}
        end
      end
    end

    class Factory
      include Identifier

      attr_reader :table_data, :work_packages_by_identifier, :relations

      def initialize(table_data)
        @table_data = table_data
        @work_packages_by_identifier = {}
        @relations = []
      end

      def create
        warn_for_existing_work_packages_with_same_identifier
        table_data.work_package_identifiers.each do |identifier|
          create_work_package(identifier)
        end
        # create relations only after having created all work packages
        table_data.work_package_identifiers.each do |identifier| # rubocop:disable Style/CombinableLoops
          create_relations(identifier)
        end
        [work_packages_by_identifier, relations]
      end

      def warn_for_existing_work_packages_with_same_identifier
        existing_identifiers = WorkPackage.pluck(:subject).map { |subject| to_identifier(subject) }
        identical_identifiers = existing_identifiers & table_data.work_package_identifiers
        if identical_identifiers.any?
          puts <<~MESSAGE
            [let_work_packages] Warning: existing work packages with identical identifiers found: #{identical_identifiers.map(&:inspect).join(', ')}
            [let_work_packages] This can cause failures when checking work package with `expect_work_packages(WorkPackage.all)`"
          MESSAGE
          puts "[let_work_packages] Current example is #{RSpec.current_example.location}" if RSpec.current_example
        end
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

      def create_relations(identifier)
        work_package_relations(identifier).each do |relation|
          to = find_work_package_by_name(relation[:with])
          from = work_packages_by_identifier[identifier]
          extra_attributes = { lag: relation[:lag] }.compact
          relations << FactoryBot.create(
            :relation,
            relation_type: relation[:type],
            from:,
            to:,
            **extra_attributes
          )
        end
      end

      def find_work_package_by_name(name)
        identifier = to_identifier(name)
        work_package = work_packages_by_identifier[identifier]
        if work_package.nil?
          raise "Work package with name #{name.inspect} (identifier: #{identifier.inspect}) not found. " \
                "Available work package identifiers: #{work_packages_by_identifier.keys}."
        end
        work_package
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

      def work_package_data(identifier)
        table_data.work_packages_data.find { |wpa| wpa[:identifier] == identifier.to_sym }
      end

      def work_package_attributes(identifier)
        work_package_data(identifier)[:attributes]
      end

      def work_package_relations(identifier)
        work_package_data(identifier)[:relations]&.values || []
      end
    end
  end
end

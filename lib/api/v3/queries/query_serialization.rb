#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Queries
      module QuerySerialization
        ##
        # Overriding this to initialize properties whose values depend on the "_links" attribute.
        def from_hash(hash)
          query = super

          initialize_links! query, hash

          query
        end

        def columns
          represented.columns.map do |column|
            ::API::V3::Queries::Columns::QueryColumnRepresenter.new(column)
          end
        end

        def filters
          represented.filters.map do |filter|
            ::API::V3::Queries::Filters::QueryFilterInstanceRepresenter.new(filter)
          end
        end

        def filters=(filters_hash)
          represented.filters = []

          filters_hash.each do |filter_attributes|
            name = get_filter_name filter_attributes
            operator = get_filter_operator filter_attributes

            if name && operator
              represented.add_filter name, operator, get_filter_values(filter_attributes)
            else
              raise API::Errors::InvalidRequestBody, "Could not read filter from: #{filter_attributes}"
            end
          end
        end

        def sort_by
          return unless represented.sort_criteria

          map_with_sort_by_as_decorated(represented.sort_criteria) do |sort_by|
            ::API::V3::Queries::SortBys::QuerySortByRepresenter.new(sort_by)
          end
        end

        def group_by
          return unless represented.grouped?

          column = represented.group_by_column

          ::API::V3::Queries::GroupBys::QueryGroupByRepresenter.new(column)
        end

        module_function

        def convert_attribute(attribute)
          ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
        end

        def get_filter_name(filter_attributes)
          href = filter_attributes.dig("_links", "filter", "href")
          id = id_from_href "queries/filters", href

          ::API::Utilities::QueryFiltersNameConverter.to_ar_name id, refer_to_ids: true if id
        end

        def get_filter_operator(filter_attributes)
          op_href = filter_attributes.dig("_links", "operator", "href")

          id_from_href "queries/operators", op_href
        end

        def get_filter_values(filter_attributes)
          filter_attributes["values"] ||
            Array(filter_attributes.dig("_links", "values"))
              .map { |value| id_from_href nil, value["href"] }
              .compact
        end

        def initialize_links!(query, attributes)
          query.project_id = get_project_id(attributes) || query.project_id
          query.group_by = get_group_by(attributes) || query.group_by
          query.column_names = get_columns(attributes) || query.columns
          query.sort_criteria = get_sort_criteria(attributes) || query.sort_criteria
        end

        def get_user_id(query_attributes)
          href = query_attributes.dig("_links", "user", "href")

          id_from_href "users", href
        end

        def get_project_id(query_attributes)
          href = query_attributes.dig("_links", "project", "href")
          id = id_from_href "projects", href

          if id.to_i != 0
            id # return numerical ID
          else
            Project.where(identifier: id).pluck(:id).first # lookup Project by identifier
          end
        end

        def get_sort_criteria(query_attributes)
          criteria = Array(query_attributes.dig("_links", "sortBy")).map do |sort_by|
            if id = id_from_href("queries/sort_bys", sort_by.href)
              column, direction = id.split("-") # e.g. ["start_date", "desc"]

              if column && direction
                column = ::API::Utilities::PropertyNameConverter.to_ar_name(column, context: WorkPackage.new)
                direction = nil unless ["asc", "desc"].include? direction

                [column, direction]
              end
            end
          end

          criteria.compact.presence
        end

        def get_group_by(query_attributes)
          href = query_attributes.dig "_links", "groupBy", "href"
          attr = id_from_href "queries/group_bys", href

          ::API::Utilities::PropertyNameConverter.to_ar_name(attr, context: WorkPackage.new) if attr
        end

        def get_columns(query_attributes)
          columns = Array(query_attributes.dig("_links", "columns")).map do |column|
            name = id_from_href "queries/columns", column.href

            ::API::Utilities::PropertyNameConverter.to_ar_name(name, context: WorkPackage.new) if name
          end

          columns.map(&:to_sym).compact.presence
        end

        def id_from_href(expected_namespace, href)
          return nil if href.blank?

          ::API::Utilities::ResourceLinkParser.parse_id(
            href,
            property: (expected_namespace && expected_namespace.split("/").last) || "filter_value",
            expected_version: "3",
            expected_namespace: expected_namespace
          )
        end

        def map_with_sort_by_as_decorated(sort_criteria)
          sort_criteria.map do |attribute, order|
            decorated = ::API::V3::Queries::SortBys::SortByDecorator.new(attribute, order)

            yield decorated
          end
        end
      end
    end
  end
end

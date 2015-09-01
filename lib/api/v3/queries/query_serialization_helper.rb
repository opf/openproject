#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Queries
      class QuerySerializationHelper
        attr_reader :query

        def initialize(query)
          @query = query
        end

        def parse_columns(columns)
          @query.column_names = columns.map { |name| api_to_ar_name name }
        end

        def format_columns
          return nil unless @query.column_names
          @query.column_names.map { |name| ar_to_api_name name }
        end

        # Expected format looks like:
        # [
        #   {
        #     "filtered_field_name": {
        #       "operator": "a name for a filter operation",
        #       "values": ["values", "for the", "operation"]
        #     }
        #   },
        #   { /* more filters if needed */}
        # ]
        def parse_filters(filters)
          filters = Array(filters)
          operators = {}
          values = {}
          filters.each do |filter|
            attribute = filter.keys.first # there should only be one attribute per filter
            ar_attribute = api_to_ar_name attribute, append_id: true
            operators[ar_attribute] = filter[attribute]['operator']
            values[ar_attribute] = filter[attribute]['values']
          end

          @query.filters = []
          @query.add_filters(values.keys, operators, values)
        end

        def format_filters
          @query.filters.map { |filter|
            attribute = ar_to_api_name filter.field
            {
              attribute => { operator: filter.operator, values: filter.values }
            }
          }
        end

        def parse_sorting(sortings)
          @query.sort_criteria = sortings.map { |(attribute, order)|
            [api_to_ar_name(attribute), order]
          }
        end

        def format_sorting
          return nil unless @query.sort_criteria
          @query.sort_criteria.map { |attribute, order|
            [ar_to_api_name(attribute), order]
          }
        end

        def parse_group_by(attribute)
          @query.group_by = api_to_ar_name attribute
        end

        def format_group_by
          @query.grouped? ? ar_to_api_name(@query.group_by) : nil
        end

        private

        def api_to_ar_name(attribute, append_id: false)
          @conversion_wp ||= WorkPackage.new
          ::API::Utilities::PropertyNameConverter.to_ar_name(attribute,
                                                             context: @conversion_wp,
                                                             refer_to_ids: append_id)
        end

        def ar_to_api_name(attribute)
          ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
        end
      end
    end
  end
end

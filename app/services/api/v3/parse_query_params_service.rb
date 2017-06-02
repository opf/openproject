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
    class ParseQueryParamsService
      def call(params)
        parsed_params = {}

        parsed_params[:group_by] = group_by_from_params(params)

        error_result = with_service_error_on_json_parse_error do
          parsed_params[:filters] = filters_from_params(params)

          parsed_params[:sort_by] = sort_by_from_params(params)
        end
        return error_result if error_result

        parsed_params[:columns] = columns_from_params(params)

        parsed_params[:display_sums] = boolearize(params[:showSums])

        parsed_params[:timeline_visible] = boolearize(params[:timelineVisible])

        parsed_params[:timeline_zoom_level] = params[:timelineZoomLevel]

        parsed_params[:show_hierarchies] = boolearize(params[:showHierarchies])

        ServiceResult.new(success: true,
                          result: without_empty(parsed_params, params.keys))
      end

      def group_by_from_params(params)
        convert_attribute(params[:group_by] || params[:groupBy] || params[:g])
      end

      def sort_by_from_params(params)
        return unless params[:sortBy]

        parse_sorting_from_json(params[:sortBy])
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
      def filters_from_params(params)
        return unless params[:filters]

        filters = params[:filters]
        filters = JSON.parse filters if filters.is_a? String

        filters.each_with_object([]) do |filter, array|
          attribute = filter.keys.first # there should only be one attribute per filter
          operator =  filter[attribute]['operator']
          values = filter[attribute]['values']
          ar_attribute = convert_filter_attribute attribute, append_id: true

          internal_representation = { field: ar_attribute,
                                      operator: operator,
                                      values: values }
          array << internal_representation
        end
      end

      def columns_from_params(params)
        columns = params[:columns] || params[:c] || params[:column_names]

        return unless columns

        columns.map do |column|
          convert_attribute(column)
        end
      end

      def boolearize(value)
        if value == 'true'
          true
        elsif value == 'false'
          false
        end
      end

      ##
      # Maps given field names coming from the frontend to the actual names
      # as expected by the query. This works slightly different to what happens
      # in #column_names_from_params. For instance while they column name is
      # :type the expected field name is :type_id.
      #
      # Examples:
      #   * status => status_id
      #   * progresssDone => done_ratio
      #   * assigned => assigned_to
      #   * customField1 => cf_1
      #
      # @param query [Query] Query for which to get the correct field names.
      # @param field_names [Array] Field names as read from the params.
      # @return [Array] Returns a list of fixed field names. The list may contain nil values
      #                 for fields which could not be found.
      def fix_field_array(field_names)
        return [] if field_names.nil?

        field_names
          .map { |name| convert_attribute name, append_id: true }
      end

      def parse_sorting_from_json(json)
        JSON.parse(json).map do |order|
          attribute, direction = if order.is_a?(Array)
                                   [order.first, order.last]
                                 elsif order.is_a?(String)
                                   order.split(':')
                                 end

          [convert_attribute(attribute), direction]
        end
      end

      def convert_attribute(attribute, append_id: false)
        ::API::Utilities::WpPropertyNameConverter.to_ar_name(attribute,
                                                             refer_to_ids: append_id)
      end

      def convert_filter_attribute(attribute, append_id: false)
        ::API::Utilities::QueryFiltersNameConverter.to_ar_name(attribute,
                                                               refer_to_ids: append_id)
      end

      def with_service_error_on_json_parse_error
        yield

        nil
      rescue ::JSON::ParserError => error
        result = ServiceResult.new
        result.errors.add(:base, error.message)
        return result
      end

      def without_empty(hash, exceptions)
        exceptions = exceptions.map(&:to_sym)
        hash.select { |k, v| v.present? || v == false || exceptions.include?(k) }
      end
    end
  end
end

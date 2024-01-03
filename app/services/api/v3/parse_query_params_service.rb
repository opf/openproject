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

module API
  module V3
    class ParseQueryParamsService
      KEYS_GROUP_BY = %i(group_by groupBy g).freeze
      KEYS_COLUMNS = %i(columns c column_names columns[]).freeze

      def call(params)
        json_parsed = json_parsed_params(params)
        return json_parsed if json_parsed.failure?

        parsed = parsed_params(params)
        return parsed if parsed.failure?

        result = without_empty(parsed.result.merge(json_parsed.result), determine_allowed_empty(params))

        ServiceResult.success(result:)
      end

      private

      def json_parsed_params(params)
        parsed = {
          filters: filters_from_params(params),
          sort_by: sort_by_from_params(params),
          timeline_labels: timeline_labels_from_params(params)
        }

        ServiceResult.success result: parsed
      rescue ::JSON::ParserError => e
        result = ServiceResult.failure
        result.errors.add(:base, e.message)
        result
      end

      # rubocop:disable Metrics/AbcSize
      def parsed_params(params)
        ServiceResult.success result: {
          group_by: group_by_from_params(params),
          columns: columns_from_params(params),
          display_sums: boolearize(params[:showSums]),
          timeline_visible: boolearize(params[:timelineVisible]),
          timeline_zoom_level: params[:timelineZoomLevel],
          highlighting_mode: params[:highlightingMode],
          highlighted_attributes: highlighted_attributes_from_params(params),
          display_representation: params[:displayRepresentation],
          show_hierarchies: boolearize(params[:showHierarchies]),
          include_subprojects: boolearize(params[:includeSubprojects]),
          timestamps: Timestamp.parse_multiple(params[:timestamps])
        }
      rescue ArgumentError => e
        result = ServiceResult.failure
        result.errors.add(:base, e.message)
        result
      end
      # rubocop:enable Metrics/AbcSize

      def determine_allowed_empty(params)
        allow_empty = params.keys
        allow_empty << :group_by if group_by_empty?(params)

        allow_empty
      end

      # Group will be set to nil if parameter exists but set to empty string ('')
      def group_by_from_params(params)
        return nil unless params_exist?(params, KEYS_GROUP_BY)

        attribute = params_value(params, KEYS_GROUP_BY)
        if attribute.present?
          convert_attribute attribute
        end
      end

      def sort_by_from_params(params)
        return unless params[:sortBy]

        parse_sorting_from_json(params[:sortBy])
      end

      def timeline_labels_from_params(params)
        return unless params[:timelineLabels]

        JSON.parse(params[:timelineLabels])
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
        filters = params[:filters] || params[:filter]
        return unless filters

        filters = JSON.parse filters if filters.is_a? String

        filters.map do |filter|
          filter_from_params(filter)
        end
      end

      def filter_from_params(filter)
        attribute = filter.keys.first # there should only be one attribute per filter
        operator =  filter[attribute]['operator']
        values = Array(filter[attribute]['values'])
        ar_attribute = convert_filter_attribute attribute, append_id: true

        { field: ar_attribute,
          operator:,
          values: }
      end

      def columns_from_params(params)
        columns = params_value(params, KEYS_COLUMNS)

        return unless columns

        columns.map do |column|
          convert_attribute(column)
        end
      end

      def highlighted_attributes_from_params(params)
        highlighted_attributes = Array(params[:highlightedAttributes].presence)

        return if highlighted_attributes.blank?

        highlighted_attributes.map do |href|
          attr = href.split('/').last
          convert_attribute(attr)
        end
      end

      def boolearize(value)
        case value
        when 'true'
          true
        when 'false'
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
          attribute, direction = case order
                                 when Array
                                   [order.first, order.last]
                                 when String
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

      def params_exist?(params, symbols)
        unsafe_params(params).detect { |k, _| symbols.include? k.to_sym }
      end

      def params_value(params, symbols)
        params.slice(*symbols).first&.last
      end

      ##
      # Access the parameters as a hash, which has been deprecated
      def unsafe_params(params)
        if params.is_a? ActionController::Parameters
          params.to_unsafe_h
        else
          params
        end
      end

      def without_empty(hash, exceptions)
        exceptions = exceptions.map(&:to_sym)
        hash.select { |k, v| v.present? || v == false || exceptions.include?(k) }
      end

      def group_by_empty?(params)
        params_exist?(params, KEYS_GROUP_BY) &&
          params_value(params, KEYS_GROUP_BY).blank?
      end
    end
  end
end

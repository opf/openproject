# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++
module Queries
  class ParamsParser
    class << self
      def parse(params)
        query_params = {}

        query_params[:filters] = parse_filters_from_params(params) if params[:filters].present?
        query_params[:orders] = parse_orders_from_params(params) if params[:sortBy].present?

        query_params
      end

      private

      def parse_filters_from_params(params)
        filters = params[:filters].split(/(?<!\\)&/)

        filters.map do |filter|
          filter_parts = filter.split

          {
            attribute: filter_parts[0],
            operator: filter_parts[1],
            values: parse_filter_value(filter_parts[2..].join(' '))
          }
        end
      end

      def parse_filter_value(values)
        if values.start_with?("[") && values.end_with?("]")
          values[1..-2].scan(/['"](.*?)['"]/).flatten.map { |v| escape_filter_value(v) }
        else
          [escape_filter_value(values.gsub('\&', '&'))]
        end
      end

      def escape_filter_value(value)
        if value.start_with?('"') && value.end_with?('"')
          value[1..-2].gsub('\&', '&').gsub('\"', '"')
        else
          value.gsub('\&', '&')
        end
      end

      def parse_orders_from_params(params)
        JSON.parse(params[:sortBy])
            .to_h
            .map { |k, v| { attribute: k, direction: v } }
      rescue JSON::ParserError
        [{ attribute: 'invalid', direction: 'asc' }]
      end
    end
  end
end

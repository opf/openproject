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
        query_params[:selects] = parse_columns_from_params(params) if params[:columns].present?

        query_params
      end

      private

      def parse_filters_from_params(params)
        FilterParser.new(params[:filters]).parse
      end

      def parse_orders_from_params(params)
        JSON.parse(params[:sortBy])
            .to_h
            .map { |k, v| { attribute: k, direction: v } }
      rescue JSON::ParserError
        [{ attribute: 'invalid', direction: 'asc' }]
      end

      def parse_columns_from_params(params)
        params[:columns].split
      end
    end

    class FilterParser
      def initialize(string)
        @buffer = StringScanner.new(string)
      end

      def parse
        filters = []

        while !@buffer.eos?
          filters << parse_filter
        end

        filters
      end

      private

      def parse_filter
        consume_ampersand

        {
          attribute: parse_name,
          operator: parse_operator,
          values: parse_values
        }
      end

      def consume_ampersand
        case @buffer.peek(1)
        when '&', /\s/
          @buffer.getch
          consume_ampersand
        end
      end

      def parse_name
        @buffer.scan_until(/\s|\z/).strip
      end

      def parse_operator
        @buffer.scan_until(/\s|\z/).strip
      end

      def parse_values
        case @buffer.peek(1)
        when '"'
          parse_doublequoted_value
        when "'"
          parse_singlequoted_value
        when '['
          parse_array_value
        when '&'
          []
        else
          parse_unguarded_value
        end
      end

      def parse_doublequoted_value
        @buffer.getch
        [@buffer.scan_until(/(?<!\\)"|\z/).delete_suffix('"').delete("\\")]
      end

      def parse_singlequoted_value
        @buffer.getch
        [@buffer.scan_until(/(?<!\\)'|\z/).delete_suffix("'").delete("\\")]
      end

      def parse_unguarded_value
        value = @buffer
                  .scan_until(/&|\z/)
                  .delete_suffix('&')

        [value]
      end

      def parse_array_value
        @buffer
          .scan_until(/]|\z/)
          .delete_suffix(']')
          .delete_prefix('[')
          .scan(/(?:'([^']*)')|(?:"([^"]*)")/)
          .flatten
          .compact
      end
    end
  end
end

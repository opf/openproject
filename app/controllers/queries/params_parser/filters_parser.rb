# frozen_string_literal: true

# -- copyright
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
# ++
module Queries
  class ParamsParser
    class FiltersParser
      # Everything up to the first quote that is not escaped. A backslash escapes
      # the character following it, so it takes two of them to end on one.
      DOUBLE_QUOTED_VALUE = /(?:[^"\\]|\\.)*"|\z/m
      SINGLE_QUOTED_VALUE = /(?:[^'\\]|\\.)*'|\z/m

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
        when "&", /\s/
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
        when "["
          parse_array_value
        when "&"
          []
        else
          parse_unguarded_value
        end
      end

      def parse_doublequoted_value
        @buffer.getch
        [unescape(@buffer.scan_until(DOUBLE_QUOTED_VALUE).delete_suffix('"'))]
      end

      def parse_singlequoted_value
        @buffer.getch
        [unescape(@buffer.scan_until(SINGLE_QUOTED_VALUE).delete_suffix("'"))]
      end

      def unescape(value)
        value.gsub(/\\(.)/m, '\1')
      end

      def parse_unguarded_value
        value = @buffer
                  .scan_until(/&|\z/)
                  .delete_suffix("&")

        [value]
      end

      # Only quoted entries are values; anything else is consumed and dropped, which
      # also keeps an unterminated array from looping forever.
      def parse_array_value
        @buffer.getch
        values = []

        until @buffer.eos?
          @buffer.skip(/[\s,]*/)
          break if @buffer.skip(/]/)

          case @buffer.peek(1)
          when '"' then values.concat(parse_doublequoted_value)
          when "'" then values.concat(parse_singlequoted_value)
          else @buffer.getch
          end
        end

        values
      end
    end
  end
end

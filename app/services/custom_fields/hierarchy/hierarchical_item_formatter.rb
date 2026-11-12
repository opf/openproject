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

module CustomFields
  module Hierarchy
    class HierarchicalItemFormatter
      include NumberFormatHelper

      class << self
        def default
          @default ||= new
        end
      end

      # @param [Boolean] path Show the full item ancestor path if true
      # @param [Boolean] label Show the item label if true
      # @param [Boolean] suffix Show the item short or weight if true
      # @param [Boolean] suffix_parentheses Wrap suffix in parentheses.
      # @param [Integer] number_length_limit If formatting numbers, restrict the whole length of the number to the
      # given limit before falling back to scientific notation.
      # @param [Integer] number_integer_digit_limit If formatting numbers, restrict the integer part of the number to
      # the given limit before falling back to scientific notation.
      # @param [Integer] number_precision If formatting numbers, round to the given precision.
      def initialize(path: false,
                     label: true,
                     suffix: true,
                     suffix_parentheses: true,
                     number_length_limit: 9,
                     number_integer_digit_limit: 8,
                     number_precision: 4)
        @path = path
        @label = label
        @suffix = suffix
        @suffix_parentheses = suffix_parentheses
        @number_length_limit = number_length_limit
        @number_integer_digit_limit = number_integer_digit_limit
        @number_precision = number_precision
      end

      def format(item:)
        path = []
        path << ancestors(item) if @path
        path << item.label if @label

        str_parts = []
        str_parts << path.join(" / ") if path.present?

        if @suffix
          suffix = format_suffix(item)
          str_parts << suffix if suffix.present?
        end

        str_parts.join(" ")
      end

      private

      def ancestors(item) = persistence_service.get_ancestors(item:).value!.filter_map(&:label)

      def format_suffix(item)
        return "" if item.short.nil? && item.weight.nil?

        opts = {
          length_limit: @number_length_limit,
          digits: @number_integer_digit_limit,
          precision: @number_precision
        }

        str = item.short.presence || number_with_limit(item.weight, opts)

        @suffix_parentheses ? "(#{str})" : str
      end

      def persistence_service
        @persistence_service ||= HierarchicalItemService.new
      end
    end
  end
end

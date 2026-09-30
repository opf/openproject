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

module API
  module Decorators
    class AggregationGroup < Single
      def initialize(group_key, count, query:, current_user:)
        @count = count
        @query = query

        @links =
          if group_key.is_a?(Array)
            group_key.map do |element|
              {
                href: ::API::V3::Utilities::ResourceLinkGenerator.make_link(element),
                title: element.to_s
              }
            end
          else
            [
              {
                href: ::API::V3::Utilities::ResourceLinkGenerator.make_link(group_key)
              }
            ]
          end

        super(group_key, current_user:)
      end

      links :valueLink do
        @links
      end

      property :value,
               exec_context: :decorator,
               render_nil: true

      property :count,
               exec_context: :decorator,
               getter: ->(*) { count },
               render_nil: true

      def model_required?
        false
      end

      attr_reader :count,
                  :query

      def value
        case represented
        when TrueClass, FalseClass
          represented
        when Array
          represented.empty? ? nil : represented.map(&:to_s).sort.join(", ")
        else
          represented&.to_s
        end
      end

      def convert_attribute(attribute)
        ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
      end
    end
  end
end

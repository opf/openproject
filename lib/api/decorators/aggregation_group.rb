#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module Decorators
    class AggregationGroup < Single
      def initialize(group_key, count, query:, sums: nil, current_user:)
        @count = count
        @sums = sums
        @query = query

        if group_key.is_a?(Array)
          group_key = set_links!(group_key)
        end

        @link = ::API::V3::Utilities::ResourceLinkGenerator.make_link(group_key)

        super(group_key, current_user: current_user)
      end

      links :valueLink do
        if @links
          @links
        elsif @link
          [{ href: @link }]
        else
          []
        end
      end

      link :groupBy do
        converted_name = convert_attribute(query.group_by_column.name)

        {
          href: api_v3_paths.query_group_by(converted_name),
          title: query.group_by_column.caption
        }
      end

      property :value,
               exec_context: :decorator,
               render_nil: true

      property :count,
               exec_context: :decorator,
               getter: ->(*) { count },
               render_nil: true

      property :sums,
               exec_context: :decorator,
               getter: ->(*) {
                 ::API::V3::WorkPackages::WorkPackageSumsRepresenter.create(sums, current_user) if sums
               },
               render_nil: false

      def has_sums?
        sums.present?
      end

      def model_required?
        false
      end

      attr_reader :sums,
                  :count,
                  :query

      ##
      # Initializes the links collection for this group if the group has multiple keys
      #
      # @return [String] A new group key for the multi value custom field.
      def set_links!(group_key)
        @links = group_key.map do |opt|
          {
            href: ::API::V3::Utilities::ResourceLinkGenerator.make_link(opt),
            title: opt.to_s
          }
        end

        if group_key.empty?
          nil
        else
          group_key.map(&:name).sort.join(", ")
        end
      end

      def value
        if query.group_by_column.name == :done_ratio
          "#{represented}%"
        elsif represented == true || represented == false
          represented
        else
          represented ? represented.to_s : nil
        end
      end

      def convert_attribute(attribute)
        ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
      end
    end
  end
end

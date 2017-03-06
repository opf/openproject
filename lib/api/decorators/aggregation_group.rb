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
  module Decorators
    class AggregationGroup < Single
      def initialize(group_key, count, query:, sums: nil)
        @count = count
        @sums = sums
        @query = query

        group_key = set_links!(query, group_key) || group_key

        @link = ::API::V3::Utilities::ResourceLinkGenerator.make_link(group_key)

        super(group_key, current_user: nil)
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
               getter: -> (*) { represented ? represented.to_s : nil },
               render_nil: true

      property :count,
               exec_context: :decorator,
               getter: -> (*) { count },
               render_nil: true

      property :sums,
               exec_context: :decorator,
               getter: -> (*) {
                 ::API::V3::WorkPackages::WorkPackageSumsRepresenter.create(sums) if sums
               },
               render_nil: false

      def has_sums?
        sums.present?
      end

      def model_required?
        false
      end

      private

      attr_reader :sums,
                  :count,
                  :query

      ##
      # Initializes the links collection for this group if the query is being grouped by
      # a multi value custom field. In that case an updated group_key is returned too.
      #
      # @return [String] A new group key for the multi value custom field.
      def set_links!(query, group_key)
        if multi_value_custom_field? query
          options = link_options query, group_key

          if options
            @links = options.map do |opt|
              {
                href: ::API::V3::Utilities::ResourceLinkGenerator.make_link(opt.id.to_s),
                title: opt.value
              }
            end

            options.map(&:value).join(", ")
          end
        end
      end

      def multi_value_custom_field?(query)
        column = query.group_by_column

        column.is_a?(QueryCustomFieldColumn) && column.custom_field.multi_value?
      end

      def link_options(query, group_key)
        query.group_by_column.custom_field.custom_options.where(id: group_key.to_s.split("."))
      end

      def convert_attribute(attribute)
        ::API::Utilities::PropertyNameConverter.from_ar_name(attribute)
      end
    end
  end
end

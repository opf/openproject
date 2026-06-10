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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module AttributeGroups
    class Transformer
      def initialize(groups:, user:)
        @groups = groups
        @user = user
      end

      def call
        return ServiceResult.success(result: []) if groups.blank?

        transformed_groups = []

        groups.each do |group|
          transformed_group = if group[:type] == "query"
                                transform_query_group(group)
                              else
                                transform_attribute_group(group)
                              end

          return transformed_group if transformed_group.is_a?(ServiceResult)

          transformed_groups << transformed_group
        end

        ServiceResult.success(result: transformed_groups)
      end

      private

      attr_reader :groups, :user

      def transform_attribute_group(group)
        attributes = group[:attributes].pluck(:key)

        return [group[:name], attributes] if group[:key].blank?

        build_default_attribute_group(group, attributes)
      end

      def transform_query_group(group)
        name = group[:name]
        result = ::WorkPackageTypes::FormConfiguration::EmbeddedQueryBuilder.build(
          query_props: group[:query],
          name: "Embedded table: #{name}",
          user:
        )

        return result if result.failure?

        [name, [result.result]]
      end

      def build_default_attribute_group(group, attributes)
        key = group[:key].to_sym
        display_name = customized_display_name(group, key)
        result = [key, attributes]
        result << display_name if display_name.present?
        result
      end

      def customized_display_name(group, key)
        return if group[:name].blank?

        group[:name] unless group[:name] == default_group_name(key)
      end

      def default_group_name(key)
        label = Type.default_groups[key]
        label ? I18n.t(label, default: key.to_s) : key.to_s
      end
    end
  end
end

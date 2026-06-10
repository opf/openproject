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

require_relative "base"

module Queries::Filters::Shared
  module CustomFields
    class ListOptional < Base
      delegate :field_format, to: :custom_field, allow_nil: true

      def value_objects
        case field_format
        when "version"
          ::Version.where(id: values)
        when "list"
          custom_field.custom_options.where(id: values)
        else
          super
        end
      end

      def allowed_values
        options = field_format == "version" ? { scope: :visible } : {}
        custom_field.possible_values_options(project, options:)
      end

      def ar_object_filter?
        true
      end

      def type
        :list_optional
      end

      def autocomplete_options # rubocop:disable Metrics/AbcSize
        all_items = if custom_field.version?
                      allowed_values.map { |name, id, project_name| { name:, id:, project_name: } }
                    else
                      allowed_values.map { |name, id| { name:, id: } }
                    end
        options = { items: all_items }
        options[:groupBy] = "project_name" if custom_field.version?

        {
          component: "opce-autocompleter",
          bindValue: "id",
          bindLabel: "name",
          hideSelected: true,
          defaultData: false
        }.merge(options).merge(model: all_items.select { |item| values.include?(item[:id]) })
      end

      protected

      def condition
        return super unless customized_strategy?

        customized_model = custom_field_context.model

        operator_strategy.sql_for_customized(
          values_replaced,
          custom_field.id,
          Arel.sql(custom_field_context.customized_type),
          Arel.sql("#{customized_model.table_name}.id")
        )
      end

      def customized_strategy?
        [Queries::Operators::CustomFields::EqualsAll, Queries::Operators::CustomFields::NotEqualsAll].include?(operator_strategy)
      end

      def type_strategy_class
        ::Queries::Filters::Strategies::CfListOptional
      end
    end
  end
end

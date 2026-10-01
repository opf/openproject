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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Queries::Filters::Shared
  module CustomFields
    class Base < Queries::Filters::Base
      include Queries::Filters::Serializable

      attr_reader :custom_field, :custom_field_context

      def initialize(custom_field:, custom_field_context:, **options)
        name = custom_field.column_name.to_sym

        @custom_field = custom_field
        @custom_field_context = custom_field_context
        self.model = custom_field_context.model
        super(name, options)
      end

      def self.create!(custom_field:, custom_field_context:, **)
        new(custom_field:, custom_field_context:, **)
      end

      def project
        context.try(:project)
      end

      def available?
        custom_field.present? && custom_field_context.custom_fields(context).include?(custom_field)
      end

      def order
        20
      end

      def human_name
        custom_field.name
      end

      def allowed_values
        custom_field.possible_values_options(project)
      end

      def type_strategy
        @type_strategy ||= type_strategy_class.new(self)
      end

      def strategies
        # Override the integer and float strategies, for simplicity
        # calculated_value hijacks float instead of adding separate strategy.
        {
          **Queries::Filters::STRATEGIES,
          string: Queries::Filters::Strategies::CfString,
          text: Queries::Filters::Strategies::CfText,
          date: Queries::Filters::Strategies::CfDate,
          hierarchy: Queries::Filters::Strategies::CfHierarchy,
          integer: Queries::Filters::Strategies::CfInteger,
          float: if custom_field.field_format == "calculated_value"
                   Queries::Filters::Strategies::CfCalculatedValue
                 else
                   Queries::Filters::Strategies::CfFloat
                 end
        }
      end

      def type
        case custom_field.field_format
        when "float", "calculated_value"
          :float
        when "int"
          :integer
        when "text"
          :text
        when "date"
          :date
        when "hierarchy", "weighted_item_list"
          :hierarchy
        else
          :string
        end
      end

      def where
        model_db_table = model.table_name

        <<~SQL.squish
          #{model_db_table}.id IN (
            SELECT
              #{model_db_table}.id
            FROM #{model_db_table}
            #{custom_field_context.where_subselect_joins(custom_field)}
            WHERE
              #{condition}
          )
        SQL
      end

      def error_messages
        messages = errors.full_messages
                         .join(" #{I18n.t('support.array.sentence_connector')} ")

        human_name + I18n.t(default: " %<message>s", message: messages)
      end

      protected

      def condition
        [
          custom_field_context.where_subselect_conditions,
          operator_strategy.sql_for_field(values_replaced, CustomValue.table_name, "value")
        ].compact.join(" AND ")
      end

      def type_strategy_class
        strategies[type] || strategies[:inexistent]
      end
    end
  end
end

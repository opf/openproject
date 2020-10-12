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

module Queries::Filters::Shared
  module CustomFields
    class Base < Queries::Filters::Base
      include Queries::Filters::Serializable

      attr_reader :custom_field
      attr_reader :custom_field_context

      validate :custom_field_valid

      def initialize(custom_field:, custom_field_context:, **options)
        name = :"cf_#{custom_field.id}"

        @custom_field = custom_field
        @custom_field_context = custom_field_context
        self.model = custom_field_context.model
        super(name, options)
      end

      def self.create!(custom_field:, custom_field_context:, **options)
        new(custom_field: custom_field, custom_field_context: custom_field_context, **options)
      end

      def project
        context.try(:project)
      end

      def available?
        custom_field.present?
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
        strategies = Queries::Filters::STRATEGIES.dup
        # Override the integer and float strategies
        strategies[:integer] = Queries::Filters::Strategies::CfInteger
        strategies[:float] = Queries::Filters::Strategies::CfFloat

        strategies
      end

      def type
        case custom_field.field_format
        when 'float'
          :float
        when 'int'
          :integer
        when 'text'
          :text
        when 'date'
          :date
        else
          :string
        end
      end

      def where
        model_db_table = model.table_name
        cv_db_table = CustomValue.table_name

        <<-SQL
          #{model_db_table}.id IN
          (SELECT #{model_db_table}.id
          FROM #{model_db_table}
          #{custom_field_context.where_subselect_joins(custom_field)}
          WHERE #{operator_strategy.sql_for_field(values_replaced, cv_db_table, 'value')})
        SQL
      end

      def error_messages
        messages = errors.full_messages
                         .join(" #{I18n.t('support.array.sentence_connector')} ")

        human_name + I18n.t(default: ' %<message>s', message: messages)
      end

      protected

      def type_strategy_class
        strategies[type] || strategies[:inexistent]
      end

      def custom_field_valid
        if invalid_custom_field_for_context?
          errors.add(:base, I18n.t('activerecord.errors.models.query.filters.custom_fields.invalid'))
        end
      end

      def invalid_custom_field_for_context?
        if project
          invalid_custom_field_for_project?
        else
          invalid_custom_field_globally?
        end
      end

      def invalid_custom_field_globally?
        !custom_field_context.custom_fields(project).exists?(custom_field.id)
      end

      def invalid_custom_field_for_project?
        !custom_field_context.custom_fields(project).map(&:id).include? custom_field.id
      end
    end
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require_relative 'base'

module Queries::Filters::Shared
  module CustomFields
    class ListOptional < Base
      def value_objects
        case custom_field.field_format
        when 'version'
          ::Version.where(id: values)
        when 'list'
          custom_field.custom_options.where(id: values)
        else
          super
        end
      end

      def ar_object_filter?
        true
      end

      def type
        :list_optional
      end

      protected

      def where_condition
        if filtered_for_default?
          super + default_condition
        else
          super
        end
      end

      def default_condition
        case operator
        when '='
          " OR #{CustomValue.table_name}.value IS NULL"
        when '!'
          " AND #{CustomValue.table_name}.value IS NOT NULL"
        else
          ''
        end
      end

      def filtered_for_default?
        default_values = Array(custom_field.default_value).map(&:to_s)
        (values & default_values) == values
      end

      def type_strategy_class
        ::Queries::Filters::Strategies::CfListOptional
      end
    end
  end
end

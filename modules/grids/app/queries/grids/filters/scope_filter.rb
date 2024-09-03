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

module Grids
  module Filters
    class ScopeFilter < Filters::GridFilter
      def allowed_values
        raise NotImplementedError, "There would be too many candidates"
      end

      def allowed_values_subset
        grid_configs_of_values
          .filter_map do |value, config|
          next unless config && config[:class]

          if config && config[:class]
            value
          end
        end
      end

      def type
        :list
      end

      def where
        grid_configs_of_values
          .map do |_value, config|
          conditions = [class_condition(config[:class]),
                        project_id_condition(config[:project_id])]

          "(#{conditions.compact.join(' AND ')})"
        end.join(" OR ")
      end

      private

      def grid_configs_of_values
        values
          .map { |value| [value, ::Grids::Configuration.attributes_from_scope(value)] }
      end

      def class_condition(klass)
        return nil unless klass

        operator_strategy.sql_for_field([klass.name],
                                        self.class.model.table_name,
                                        "type")
      end

      def project_id_condition(project_id)
        return nil unless project_id

        unless project_id.match?(/\A\d+\z/)
          project_id = Project.find(project_id).id
        end

        operator_strategy.sql_for_field([project_id],
                                        self.class.model.table_name,
                                        "project_id")
      end

      def type_strategy
        @type_strategy ||= Queries::Filters::Strategies::HugeList.new(self)
      end

      def available_operators
        [::Queries::Operators::Equals]
      end
    end
  end
end

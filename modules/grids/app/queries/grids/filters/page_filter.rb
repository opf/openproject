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

module Grids
  module Filters
    class PageFilter < Filters::GridFilter
      def allowed_values
        raise NotImplementedError, 'There would be too many candidates'
      end

      def allowed_values_subset
        values
          .map { |page| [page, ::Grids::Configuration.attributes_from_scope(page)] }
          .map do |page, config|
            next unless config && config[:class]

            if config[:id] && config[:class].visible.exists?(config[:id]) || config[:class].visible.any?
              page
            end
          end.compact
      end

      def type
        :list
      end

      def self.key
        :page
      end

      # TODO: add condition methods for user_id and id
      def where
        values
          .map { |page| ::Grids::Configuration.attributes_from_scope(page) }
          .map do |actual_value|
            conditions = [class_condition(actual_value[:class]),
                          project_id_condition(actual_value[:project_id])]

            "(#{conditions.compact.join(' AND ')})"
          end.join(' OR ')
      end

      private

      def class_condition(klass)
        return nil unless klass

        operator_strategy.sql_for_field([klass.name],
                                        self.class.model.table_name,
                                        'type')
      end

      def project_id_condition(project_id)
        return nil unless project_id

        unless project_id.match?(/\A\d+\z/)
          project_id = Project.find(project_id).id
        end

        operator_strategy.sql_for_field([project_id],
                                        self.class.model.table_name,
                                        'project_id')
      end

      def available_operators
        [::Queries::Operators::Equals]
      end

      def type_strategy
        @type_strategy ||= Queries::Filters::Strategies::HugeList.new(self)
      end
    end
  end
end

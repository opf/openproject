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

module CustomFields
  module Hierarchy
    module Items
      class RebuildPositionCacheService < ::BaseServices::BaseContracted
        def initialize(user:, model:, contract_class: AdminOnlyContract, contract_options: {})
          self.model = model
          super(user:, contract_class:, contract_options:)
        end

        protected

        def persist(service_result)
          root = model.root

          OpenProject::Mutex.with_advisory_lock(CustomField::Hierarchy::Item, "position_update_anc_#{root.id}") do
            CustomField::Hierarchy::Item.connection.exec_update(update_sql(root))
          end

          service_result
        end

        private

        def update_sql(root)
          <<~SQL.squish
            UPDATE hierarchical_items
            SET position_cache = ranked.position
            FROM (
              SELECT id, ROW_NUMBER() OVER (ORDER BY path) AS position
              FROM (
                SELECT hih.descendant_id AS id
                     , ARRAY_AGG(COALESCE(anc.sort_order, 0) ORDER BY anc_h.generations DESC) AS path
                FROM hierarchical_item_hierarchies hih
                     JOIN hierarchical_item_hierarchies anc_h ON anc_h.descendant_id = hih.descendant_id
                     JOIN hierarchical_items anc ON anc.id = anc_h.ancestor_id
                WHERE hih.ancestor_id = #{root.id}
                GROUP BY hih.descendant_id
              ) paths
            ) ranked
            WHERE hierarchical_items.id = ranked.id;
          SQL
        end
      end
    end
  end
end

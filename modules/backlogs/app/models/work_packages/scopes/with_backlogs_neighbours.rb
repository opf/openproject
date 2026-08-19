# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages::Scopes::WithBacklogsNeighbours
  extend ActiveSupport::Concern

  class_methods do
    def with_backlogs_neighbours
      # Adds neighbour ids (prev_id, prev_prev_id, next_id) to each row in the scope,
      # computed via SQL window functions over the position-ordered list.
      #
      # These ids drive the move-up / move-down actions in the backlog UI:
      #   - prev_id: the previous sibling, only used for its presence; if nil, the
      #     current element is first in the scoped list.
      #   - prev_prev_id: second previous sibling, used as the target prev_id when moving up
      #   - next_id: the next sibling, used as the target prev_id when moving down; if nil
      #     the current element is last in the scoped list.
      #
      # The position field alone is not sufficient for the move-up / move-down actions because
      # the UI may hide certain work packages (e.g. closed ones), creating gaps that make the
      # position field unreliable.
      #
      # The subquery is required because WHERE clauses are applied before window functions
      # within a single SELECT. Chaining .find(id) directly would therefore filter rows
      # first, leaving the window function with a single row and returning nil for all
      # neighbours. Wrapping in a subquery lets the window function see the full scope,
      # then the outer query filters to the requested record.

      # In order to handle nil positions, the same default order from acts_as_list has to be
      # applied to the window function as well. This is just for matching the plugin and there should
      # be no nil positions.
      window_order = Arel.sql(
        "ORDER BY #{arel_table[:position].asc.nulls_last.to_sql}, #{arel_table[:id].asc.to_sql}"
      )

      subquery = order_by_position.select(
        "*, LAG(id)    OVER (#{window_order}) AS prev_id,
            LAG(id, 2) OVER (#{window_order}) AS prev_prev_id,
            LEAD(id)   OVER (#{window_order}) AS next_id"
      )
      WorkPackage.from(subquery, :work_packages)
    end
  end
end

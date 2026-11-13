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

module WorkPackages::Scopes::IncludeSpentTime
  extend ActiveSupport::Concern

  class_methods do
    # Returns the spent time of the work package and its descendants.
    # The visibility check is carried out on the database level and is
    # carried out on the projection. Therefore, `select` & `pluck` need to be avoided.
    def include_spent_time(user, work_package = nil)
      hours = sum_over_visible_descendants(user, "#{visible_time_entries_cte.name}.hours")

      scope = left_join_self_and_descendants(work_package)
              .with(visible_time_entries_cte.name => allowed_to_view_time_entries(user))
              .joins(join_visible_time_entries.join_sources)
              .group(:id)
              .select(hours => :hours)

      if work_package
        scope.where(id: work_package.id)
      else
        scope
      end
    end

    protected

    def join_visible_time_entries
      wp_table
        .outer_join(visible_time_entries_cte)
        .on(entity_join)
    end

    def allowed_to_view_time_entries(user)
      TimeEntry.not_ongoing.visible(user).select(:id, :entity_type, :entity_id, :hours).arel
    end

    def entity_join
      visible_time_entries_cte[:entity_type].eq("WorkPackage").and(
        visible_time_entries_cte[:entity_id].eq(wp_descendants_table[:id])
      )
    end

    def wp_table
      @wp_table ||= arel_table
    end

    def visible_time_entries_cte
      @visible_time_entries_cte ||= Arel::Table.new("visible_time_entries")
    end
  end
end

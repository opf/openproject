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

module ResourceManagement
  # Builds the user utilization dialog for a planner sub-view. The planner's
  # timeframe scopes the utilization and the listed allocations alike, so both
  # controllers opening the dialog load through here. Requires @project to be set.
  module UserAllocationsDialog
    def user_allocations_dialog_component(view:, user:)
      timeframe = planner_timeframe(view)
      allocations = allocations_in_timeframe(user, timeframe)

      ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent.new(
        project: @project,
        view:,
        user:,
        timeframe:,
        allocations:,
        overbooked_ids: ResourceAllocation.overbooked_ids(allocations)
      )
    end

    private

    # The card view always belongs to a planner, which carries the timeframe.
    # It is optional on the planner, in which case nothing scopes the dialog.
    def planner_timeframe(view)
      planner = view.parent
      return if planner.start_date.blank? || planner.end_date.blank?

      planner.start_date..planner.end_date
    end

    def allocations_in_timeframe(user, timeframe)
      scope = ResourceAllocation.allocated.for_principal(user).includes(:entity)
      scope = scope.overlapping(timeframe) if timeframe

      scope.to_a
    end
  end
end

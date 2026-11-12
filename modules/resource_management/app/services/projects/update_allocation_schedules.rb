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

module Projects::UpdateAllocationSchedules
  private

  def before_perform(*)
    @earliest_allocation_start_by_principal = earliest_allocation_start_by_principal
    @schedule_users = User.where(id: @earliest_allocation_start_by_principal.keys).to_a
    ResourceAllocations::ScheduledEntry.lock_schedules_of(@schedule_users)

    super
  end

  def earliest_allocation_start_by_principal
    ResourceAllocation
      .allocated
      .for_projects([model, *dependent_projects].map(&:id))
      .where.not(principal_id: nil)
      .group(ResourceAllocation.arel_table[:principal_id])
      .minimum(ResourceAllocation.arel_table[:start_date])
  end

  def after_perform(call)
    @schedule_users.each do |user|
      ResourceAllocations::UpdateScheduleService
        .new
        .call(users: [user], from: @earliest_allocation_start_by_principal[user.id])
    end

    super
  end
end

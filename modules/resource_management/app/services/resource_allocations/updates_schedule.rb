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

module ResourceAllocations
  module UpdatesSchedule
    SCHEDULE_ATTRIBUTES = %w[start_date end_date allocated_time state principal_id].freeze

    private

    def before_perform(*)
      super.tap do |call|
        allocation = call.result
        @schedule_users = [User.find_by(id: allocation.principal_id_in_database), allocation.principal].compact.uniq
        ScheduledEntry.lock_schedules_of(@schedule_users)
      end
    end

    def after_perform(call)
      allocation = call.result
      update_schedule(allocation) if schedule_changed?(allocation)

      super
    end

    def schedule_changed?(allocation)
      allocation.saved_changes.keys.intersect?(SCHEDULE_ATTRIBUTES) &&
        (allocation.allocated? || allocation.state_before_last_save == "allocated")
    end

    def update_schedule(allocation)
      from = [allocation.start_date_before_last_save, allocation.start_date].compact.min

      UpdateScheduleService.new.call(users: @schedule_users, from:) if @schedule_users.any?
    end
  end
end

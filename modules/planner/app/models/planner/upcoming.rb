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

module Planner
  # The user's next days after today: their "My work" tasks planned for each day and the meetings
  # they take part in, including occurrences of recurring series not created yet.
  class Upcoming < View
    DAYS_AHEAD = 7

    Day = Data.define(:date, :working, :meetings, :work_packages) do
      include Group

      def working? = working
    end

    def days
      @days ||= dates.map do |date|
        Day.new(date:,
                working: working_days.working?(date),
                meetings: meetings.select { local_date(it.start_time) == date },
                work_packages: work_packages.select { it.due_date == date })
      end
    end

    private

    def dates
      @dates ||= (1..DAYS_AHEAD).map { user.today + it }
    end

    def working_days
      @working_days ||= WorkPackages::Shared::WorkingDays.new
    end

    def work_packages
      @work_packages ||= project
                           .work_packages
                           .where(due_date: dates)
                           .includes(:status, :type, :project, :custom_values)
                           .order(:id)
                           .to_a
    end

    def meetings
      @meetings ||= MeetingOccurrences.new(user:, dates:).to_a
    end

    def local_date(time) = time.in_time_zone(user.time_zone).to_date
  end
end

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

# The interval a sprint's reports cover, in three registers: what it was planned for, what
# holds now, and how far it has actually got.
#
# A sprint that was started or completed reports from those moments rather than from the
# dates it was planned with, and one still running reports up to now once it has overrun.
#
# A sprint is planned in dates, which only become moments once a zone says where their days begin
# and end. The caller names that zone, and every time handed back is in it, so that taking a date
# off one of them answers in the same calendar the reader is reading.
module Sprints
  class Timeframe
    def initialize(sprint, zone: Time.zone)
      @sprint = sprint
      @zone = zone
    end

    # The point in time the sprint was planned to start.
    def planned_start
      sprint.start_date.in_time_zone(zone).beginning_of_day
    end

    # The point in time the sprint was planned to finish.
    # People expect the end day to still count fully as part of the sprint.
    def planned_finish
      sprint.finish_date.in_time_zone(zone).end_of_day
    end

    # The point in time at which the sprint has started or will start. A sprint yet to begin has
    # only its schedule to go on, so this is not always a moment anything happened at.
    def effective_start
      return zoned(sprint.started_at) if sprint.started_at?

      planned_start
    end

    # The point in time up until which the sprint is expected to finish.
    # The expectations change depending on what is currently known.
    # - If the sprint is completed, use that.
    # - If the sprint is just planned, use the planned time.
    # - If the sprint has started, use the planned time. But since time progresses and the plan might not be accurate,
    #   use the current time if that is later.
    def effective_finish
      return zoned(sprint.completed_at) if sprint.completed_at?

      return planned_finish unless sprint.started_at?

      [planned_finish, now].max
    end

    # The point in time the sprint has reached, which is never in the future, or nil for one that
    # has reached nothing at all.
    def measured_until
      return nil if now < effective_start

      [now, effective_finish].min
    end

    private

    attr_reader :sprint, :zone

    def now = zoned(Time.current)

    def zoned(time) = time.in_time_zone(zone)
  end
end

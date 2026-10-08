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
  # Shared by the Today, Upcoming and Overdue views, which refresh themselves via Turbo Streams.
  class BaseComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def self.for(view, user)
      case view.to_s
      when "upcoming" then UpcomingComponent.new(upcoming: Upcoming.for(user))
      when "overdue" then OverdueComponent.new(overdue: Overdue.for(user))
      when "completed" then CompletedComponent.new(completed: Completed.for(user))
      else TodayComponent.new(today: Today.for(user))
      end
    end

    private

    # Wide enough for a meeting's "start–end" in the configured time format and for a task's id
    # followed by its checkbox, so that meeting and task titles start at the same point.
    def lead_width
      latest = helpers.format_time(Time.utc(2000, 12, 31, 23, 59), include_date: false, time_zone: "UTC")

      "#{[(latest.length * 2) + 2, TaskRowComponent::ID_CHARACTERS + 5].max}ch"
    end

    def counts(group)
      return t("planner.empty_section") if group.empty?

      [
        t("planner.open_tasks", count: group.open_count),
        (t("planner.meetings", count: group.meetings.size) if group.meetings.any?)
      ].compact.join(" · ")
    end
  end
end

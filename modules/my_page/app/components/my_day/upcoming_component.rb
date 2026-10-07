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

module MyDay
  class UpcomingComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(upcoming:)
      super()
      @upcoming = upcoming
    end

    private

    attr_reader :upcoming

    def lead_width = TodayComponent.lead_width(helpers)

    def day_name(date)
      date == upcoming.user.today + 1 ? t("my_day.upcoming.tomorrow") : I18n.l(date, format: "%A")
    end

    def counts(day)
      return t("my_day.empty_section") if day.empty?

      [
        t("my_day.open_tasks", count: day.open_count),
        (t("my_day.meetings", count: day.meetings.size) if day.meetings.any?)
      ].compact.join(" · ")
    end

    def start_time(occurrence)
      helpers.format_time(occurrence.start_time, include_date: false, time_zone: upcoming.user.time_zone)
    end

    def meeting_kind(occurrence)
      recurring = occurrence.series || occurrence.meeting.recurring_meeting_id
      recurring ? t("my_day.meeting_recurring") : t("my_day.meeting_one_time")
    end

    def occurrence_path(occurrence)
      occurrence.meeting ? meeting_path(occurrence.meeting) : recurring_meeting_path(occurrence.series)
    end
  end
end

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

module RecurringMeetings
  class HumanScheduleComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include Redmine::I18n

    def initialize(recurring_meeting:)
      super

      @recurring_meeting = recurring_meeting
    end

    def schedule_text
      safe_join(
        [
          @recurring_meeting.human_frequency_schedule,
          day_of_month_skipping_info,
          start_mismatch_info
        ].compact,
        ". "
      )
    end

    def start_mismatch_info
      return unless @recurring_meeting.actual_start_differs?

      first_occurrence = helpers.content_tag(:strong,
                                             formatted_occurrence_with_zone(@recurring_meeting.first_occurrence))
      helpers.t("recurring_meeting.actual_first_occurrence_mismatch_html", first_occurrence:)
    end

    def day_of_month_skipping_info
      return unless @recurring_meeting.frequency_monthly_day_of_month?
      return unless @recurring_meeting.monthly_day > 28

      helpers.t("recurring_meeting.day_of_month_skipping_info",
                monthly_day: @recurring_meeting.monthly_day)
    end

    private

    def formatted_occurrence_with_zone(occurrence)
      formatted = format_time(occurrence, time_zone: @recurring_meeting.time_zone)

      if @recurring_meeting.time_zone_differs?
        "#{formatted} (#{friendly_timezone_name(@recurring_meeting.time_zone)})"
      else
        formatted
      end
    end
  end
end

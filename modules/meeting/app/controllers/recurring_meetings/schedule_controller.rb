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

module RecurringMeetings
  class ScheduleController < ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_login, :build_meeting
    around_action :with_user_time_zone
    no_authorization_required! :humanize_schedule

    def humanize_schedule
      [
        RecurringMeetings::HumanScheduleComponent,
        RecurringMeetings::OccurrenceCountCaptionComponent,
        RecurringMeetings::EndDateCaptionComponent
      ].each do |component|
        update_via_turbo_stream(component: component.new(recurring_meeting: @recurring_meeting))
      end

      respond_with_turbo_streams
    end

    private

    def with_user_time_zone(&)
      User.execute_as(User.current, &)
    end

    def build_meeting
      @recurring_meeting = RecurringMeeting.new(schedule_params.compact_blank)
    end

    def schedule_params
      params.expect(meeting: %i[start_date start_time_hour frequency interval monthly_day monthly_ordinal
                                monthly_weekday time_zone end_after end_date iterations])
    end
  end
end

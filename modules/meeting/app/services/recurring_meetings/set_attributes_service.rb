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
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(params)
      super

      model.change_by_system do
        if model.frequency_working_days?
          model.interval = 1
        end

        determine_current_schedule_start
      end
    end

    # current_schedule_start is used as the DTSTART of the ICS series event.
    # As a result, it needs to be conencted to the UID.
    # If DTSTART moves while the UID stays the same, some clients delete all earlier
    # occurrences
    #
    # Only RecurringMeetings::StartNewScheduleService will update it again, and
    # update DTSTART and UID together when the series already has past occurrences.
    def determine_current_schedule_start
      return if model.current_schedule_start.present?

      model.current_schedule_start = model.next_occurrence(from_time: Time.current) || model.start_time
    end

    def set_default_attributes(_params)
      model.change_by_system do
        model.time_zone = user.time_zone.name
        model.author = user
        model.duration ||= 1
      end
    end
  end
end

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

module My
  module Work
    class StackEntriesComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include OpStimulus::ControllerData
      include ScheduledHours

      options time_entries: [],
              allocations: nil,
              mode: :week,
              date: Date.current

      private

      def wrapper_data # rubocop:disable Metrics/AbcSize
        stimulus_controller_data(
          "my--work-stack",
          allocations: allocation_events_json,
          can_create: User.current.allowed_in_any_project?(:log_own_time),
          initial_date: date.iso8601,
          locale: I18n.locale,
          mode:,
          start_of_week: OpenProject::Internationalization::Date.first_day_of_week_index,
          time_entries: time_entries_json,
          time_zone: User.current.time_zone.name,
          today: User.current.today.iso8601,
          working_days:,
          working_hours: working_hours.to_json
        )
      end

      def time_entries_json
        time_entries.map do |time_entry|
          FullCalendar::TimeEntryEvent.from_time_entry(time_entry)
        end.to_json
      end

      def allocation_events_json
        (allocations&.events || []).to_json
      end

      def working_days
        Setting.working_days.map { |day| day % 7 }.sort
      end
    end
  end
end

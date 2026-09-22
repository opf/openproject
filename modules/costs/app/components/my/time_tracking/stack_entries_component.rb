# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module TimeTracking
    class StackEntriesComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      options time_entries: [],
              mode: :week,
              date: Date.current

      private

      def wrapper_data
        {
          "controller" => "my--time-tracking-stack",
          "my--time-tracking-stack-mode-value" => mode,
          "my--time-tracking-stack-time-entries-value" => time_entries_json,
          "my--time-tracking-stack-initial-date-value" => date.iso8601,
          "my--time-tracking-stack-can-create-value" => User.current.allowed_in_any_project?(:log_own_time),
          "my--time-tracking-stack-locale-value" => I18n.locale,
          "my--time-tracking-stack-start-of-week-value" => (Setting.start_of_week || 1) % 7,
          "my--time-tracking-stack-working-days-value" => working_days,
          "my--time-tracking-stack-time-zone-value" => User.current.time_zone.name
        }
      end

      def time_entries_json
        time_entries.map do |time_entry|
          FullCalendar::TimeEntryEvent.from_time_entry(time_entry)
        end.to_json
      end

      def working_days
        Setting.working_days.map { |day| day % 7 }.sort
      end
    end
  end
end

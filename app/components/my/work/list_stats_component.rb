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
  module Work
    class ListStatsComponent < ApplicationComponent
      include OpTurbo::Streamable

      options :time_entries, :date

      def wrapper_key
        "time-entries-list-stats-#{date.iso8601}"
      end

      def call
        component_wrapper do
          render(Primer::Beta::Text.new(color: :muted)) { "#{entry_count} - " } +
          render(Primer::Beta::Text.new) { total_hours }
        end
      end

      def total_hours
        total_hours = time_entries.sum(&:hours_for_calculation).round(2)
        DurationConverter.output(total_hours, format: :hours_and_minutes).presence || "0h"
      end

      def entry_count
        entries_count = time_entries.size
        "#{entries_count} #{TimeEntry.model_name.human(count: entries_count)}"
      end
    end
  end
end

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
    class ListWrapperComponent < ApplicationComponent
      include OpTurbo::Streamable
      include My::WorkHelper

      options :time_entries, :date, :mode
      options allocations: nil

      def wrapper_key
        "time-entries-list-#{options[:date].iso8601}"
      end

      def call
        component_wrapper do
          render(My::Work::TimeEntriesListComponent.new(rows: time_entries.to_a + remaining_allocations, date:, mode:))
        end
      end

      private

      def remaining_allocations
        @remaining_allocations ||= RemainingAllocations.call(allocations:, time_entries:, dates: list_section_dates(date, mode))
      end
    end
  end
end

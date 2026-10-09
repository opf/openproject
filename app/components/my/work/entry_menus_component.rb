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
    # The action menus of the cards in the calendar views, which open them at the pointer
    # through the event they belong to. Kept out of sight rather than hidden, as a popover
    # inside a `display: none` ancestor cannot open.
    class EntryMenusComponent < ApplicationComponent
      options time_entries: [],
              allocations: nil

      def call
        render(Primer::Box.new(classes: "sr-only", data: { "my-work-menus": true })) do
          safe_join(time_entry_menus + allocation_menus)
        end
      end

      private

      def time_entry_menus
        time_entries.map do |time_entry|
          menu_for(time_entry.id, TimeEntryActionMenuComponent.new(time_entry:, navigation: true))
        end
      end

      def allocation_menus
        RemainingAllocations.call(allocations:, time_entries:).map do |allocation|
          event_id = FullCalendar::ResourceAllocationEvent.id_for(allocation.scheduled_entry)
          menu_for(event_id, AllocationActionMenuComponent.new(allocation:, navigation: true))
        end
      end

      def menu_for(event_id, menu)
        render(Primer::Box.new(data: { "my-work-menu-for": event_id })) { render(menu) }
      end
    end
  end
end

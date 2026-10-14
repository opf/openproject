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
          menu_for(time_entry.id) do
            deferred_menu(menu_id: TimeEntryActionMenuComponent.menu_id(time_entry),
                          src: my_work_time_entry_menu_path(time_entry))
          end
        end
      end

      def allocation_menus
        RemainingAllocations.call(allocations:, time_entries:).select(&:visible?).map do |allocation|
          scheduled_entry = allocation.scheduled_entry

          menu_for(FullCalendar::ResourceAllocationEvent.id_for(scheduled_entry)) do
            deferred_menu(menu_id: AllocationActionMenuComponent.menu_id(scheduled_entry),
                          src: my_work_allocation_menu_path(scheduled_entry.allocation, date: allocation.allocated_on.iso8601))
          end
        end
      end

      def deferred_menu(menu_id:, src:)
        render(Primer::Alpha::ActionMenu.new(menu_id:, src:)) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t("label_more"), scheme: :invisible)
        end
      end

      def menu_for(event_id, &)
        render(Primer::Box.new(data: { "my-work-menu-for": event_id }), &)
      end
    end
  end
end

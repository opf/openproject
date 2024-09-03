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

module Components
  module WorkPackages
    class SortBy
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      def sort_via_header(name, selector: nil, descending: false)
        text = descending ? "Sort descending" : "Sort ascending"

        SeleniumHubWaiter.wait unless using_cuprite?
        open_table_column_context_menu(name, selector)
        SeleniumHubWaiter.wait unless using_cuprite?

        within_column_context_menu do
          click_button text
        end

        wait_for_network_idle
      end

      def update_criteria(first, second = nil, third = nil)
        open_modal
        SeleniumHubWaiter.wait

        [first, second, third]
          .compact
          .each_with_index do |entry, i|
          column, direction = entry
          update_nth_criteria(i, column, descending: descending?(direction))
        end

        apply_changes
      end

      def expect_criteria(first, second = nil, third = nil)
        open_modal
        SeleniumHubWaiter.wait

        [first, second, third]
          .compact
          .each_with_index do |entry, i|
          column, direction = entry
          page.within(".modal-sorting-row-#{i}") do
            expect(page).to have_css("#modal-sorting-attribute-#{i} option", text: column)
            checked_radio = (descending?(direction) ? "Descending" : "Ascending")
            expect(page.find_field(checked_radio)).to be_checked
          end
        end

        cancel_changes
      end

      def update_nth_criteria(i, column, descending: false)
        page.within(".modal-sorting-row-#{i}") do
          select column, from: "modal-sorting-attribute-#{i}"
          choose(descending ? "Descending" : "Ascending")
        end
      end

      def update_sorting_mode(mode)
        if mode === "manual"
          choose("sorting_mode_switch", option: "manual")
        else
          choose("sorting_mode_switch", option: "automatic")
        end
      end

      def open_modal
        modal = TableConfigurationModal.new
        modal.open_and_switch_to "Sort by"
      end

      def cancel_changes
        page.within(".spot-modal") do
          click_on "Cancel"
        end
      end

      def apply_changes
        page.within(".spot-modal") do
          click_on "Apply"
        end
      end

      private

      def descending?(direction)
        ["desc", "descending"].include?(direction.to_s)
      end

      def open_table_column_context_menu(name, id)
        id ||= name.downcase
        page.find(".generic-table--sort-header ##{id}").click
      end

      def within_column_context_menu(&)
        page.within("#column-context-menu", &)
      end
    end
  end
end

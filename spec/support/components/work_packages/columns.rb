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

require_relative "../autocompleter/ng_select_autocomplete_helpers"

module Components
  module WorkPackages
    class Columns
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      attr_accessor :trigger_parent

      def initialize(trigger_parent = nil)
        self.trigger_parent = trigger_parent
      end

      def column_autocompleter
        find(".columns-modal--content .op-draggable-autocomplete--input")
      end

      def close_autocompleter
        find(".columns-modal--content .op-draggable-autocomplete--input input").send_keys :escape
      end

      def column_item(name)
        find(".op-draggable-autocomplete--item", text: name)
      end

      def expect_column_not_available(name)
        modal_open? or open_modal

        column_autocompleter.click
        expect(page).to have_no_css(".ng-option", text: name, visible: :all)
        close_autocompleter
      end

      def expect_column_available(name)
        modal_open? or open_modal

        column_autocompleter.click
        expect(page).to have_css(".ng-option", text: name, visible: :all)
        close_autocompleter
      end

      def expect_alternative_available_column(search_term, displayed_name)
        column_autocompleter.click

        autocompleter_input = column_autocompleter.find("input")

        autocompleter_input.set(search_term)

        expect(page)
          .to have_css(".ng-dropdown-panel .ng-option-label", text: displayed_name)

        autocompleter_input.set(search_term)
      end

      def add(name, save_changes: true)
        open_modal unless modal_open?

        select_autocomplete column_autocompleter,
                            results_selector: ".ng-dropdown-panel-items",
                            query: name

        if save_changes
          apply
          within ".work-package-table" do
            expect(page).to have_columnheader(name)
          end
        end
      end

      def remove(name, save_changes: true)
        modal_open? or open_modal

        within_modal do
          container = column_item(name)
          container.find(".op-draggable-autocomplete--remove-item").click
        end

        apply if save_changes
      end

      def expect_checked(name)
        within_modal do
          expect(page).to have_css(".op-draggable-autocomplete--item", text: name)
        end
      end

      def expect_unchecked(name)
        within_modal do
          expect(page).to have_no_css(".op-draggable-autocomplete--item", text: name)
        end
      end

      def uncheck_all(save_changes: true)
        open_modal unless modal_open?

        within_modal do
          expect(page).to have_css(".op-draggable-autocomplete--item", minimum: 1)
          page.all(".op-draggable-autocomplete--remove-item").each(&:click)
        end

        apply if save_changes
      end

      def apply
        @opened = false

        click_button("Apply")
      end

      def open_modal
        @opened = true
        ::Components::WorkPackages::TableConfigurationModal.new(trigger_parent).open_and_switch_to "Columns"
      end

      def assume_opened
        @opened = true
      end

      private

      def within_modal(&)
        page.within(".wp-table--configuration-modal", &)
      end

      def modal_open?
        !!@opened
      end
    end
  end
end

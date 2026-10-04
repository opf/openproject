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

require "support/pages/page"

module Pages
  module Admin
    module Settings
      class ProjectPhaseDefinitions < ::Pages::Page
        def path = "/admin/settings/project_phase_definitions"

        def expect_header_to_display(text)
          expect(page).to have_css("h2", text:)
          expect(page).to have_css(".breadcrumb-item-selected a", text:)
          expect(page).to have_title("#{text} | Project life cycle | Administration | OpenProject")
        end

        def expect_listed(names)
          page.document.synchronize do
            found = page.all(:test_id, "project-phase-definition-name").collect(&:text)

            raise Capybara::ExpectationNotMet, "Expected #{names}, got #{found}" unless found == names
          end
        end

        # A move/drag response replaces the whole list via a Turbo Stream
        # update, so asserting order right after the network settles can race
        # the sortable-lists controller's re-render. Wait for it to clear its
        # busy flag first, like EnumerationAdminHelpers#expect_enumeration_move_settled.
        def expect_move_settled(names)
          expect(page).to have_no_css("[data-sortable-lists-busy]")
          expect_listed(names)
        end

        def expect_no_controls
          within "#content-body" do
            expect(page).to have_no_css(".DragHandle")
            expect(page).to have_no_css("action-menu")
          end
        end

        def expect_no_ordering_controls
          within "#content-body" do
            expect(page).to have_no_css(".DragHandle")
          end
        end

        def expect_gates_mentioned_for(definition, gates_string)
          within find_test_selector("project-phase-definition", text: definition) do
            expect(page).to have_text(gates_string)
          end
        end

        def filter_with(string)
          fill_in I18n.t("settings.project_phase_definitions.filter.label"), with: string
        end

        def clear_filter
          click_button accessible_name: "Clear"
        end

        def add
          page.click_on("Add")
        end

        def click_definition(name)
          find_test_selector("project-phase-definition-name", text: name).click_link_or_button
        end

        def click_definition_action(name, action:)
          action_menu_for(name).find(:menuitem, action).click
        end

        def move_definition(name, direction:)
          submenu = open_controlled_menu(action_menu_for(name).find(:menuitem, I18n.t(:button_move)))

          submenu.find(:menuitem, direction).click
        end

        def select_color(color)
          input = find("label", text: "Color").ancestor(".FormControl").find("input")
          input.fill_in(with: color)
          input.send_keys(:return)
        end

        def drag_definition(name, after:)
          handle = definition_row(name).find(".DragHandle")
          target = definition_row(after)
          offset_y = (target.native.rect.height / 2) - [6, target.native.rect.height / 4].min

          perform_native_drag(source: handle, target:, offset_y: offset_y.round)

          expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
        end

        private

        def definition_row(name)
          find_test_selector("project-phase-definition-name", text: name)
            .ancestor(test_selector("project-phase-definition"))
        end

        def action_menu_for(name)
          trigger = definition_row(name).find(:button, accessible_name: I18n.t(:button_actions))

          open_controlled_menu(trigger)
        end

        def open_controlled_menu(button)
          button.click
          page.find(:menu, id: button["aria-controls"])
        end
      end
    end
  end
end

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
          page.document.synchronize(10) do
            found = page.all("[data-test-selector=project-phase-definition-name]").collect(&:text)

            raise Capybara::ExpectationNotMet, "Expected #{names}, got #{found}" unless found == names
          end
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
          within page.find(test_selector("project-phase-definition"), text: definition) do
            expect(page).to have_content(gates_string)
          end
        end

        def filter_with(string)
          fill_in I18n.t("settings.project_phase_definitions.filter.label"), with: string
        end

        def clear_filter
          find("button[aria-label=Clear]").click
        end

        def add
          page.click_on("Add")
        end

        def click_definition(name)
          page.find("[data-test-selector=project-phase-definition-name]", text: name).click_link_or_button
        end

        def click_definition_action(name, action:)
          menu = page
            .find("[data-test-selector=project-phase-definition-name]", text: name)
            .ancestor("[data-test-selector=project-phase-definition]")
            .find("action-menu")

          menu.click_link_or_button

          menu.click_on(action)
        end

        def select_color(color)
          input = find("label", text: "Color").ancestor(".FormControl").find("input")
          input.fill_in(with: color)
          input.send_keys(:return)
        end
      end
    end
  end
end

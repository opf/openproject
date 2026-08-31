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
# ++

require "support/pages/page"

module Pages
  module Projects
    module Settings
      class WorkPackageTypes < Pages::Page
        include ::Components::Autocompleter::NgSelectAutocompleteHelpers

        attr_accessor :project

        def initialize(project)
          super()

          self.project = project
        end

        def path
          "/projects/#{project.identifier}/settings/work_packages/types"
        end

        def expect_type_row(variant, variant_name: nil)
          row = find_row(variant)

          expect(row).to have_text(variant.name)
          return if variant_name.nil?

          # A named variant in use says so on its own row, inside the group the type heads.
          expect(row).to have_css("[data-test-selector='project-types-variant-#{variant.id}']",
                                  text: "Variant in this project")
          expect(row).to have_text(variant_name)
        end

        def expect_no_type_row(variant)
          expect(page).to have_no_css("[data-test-selector='project-types-row-#{variant.id}']")
        end

        def remove_type(variant)
          open_type_menu(variant)
          click_on "Remove from project"
        end

        def switch_type(variant, target:)
          open_switch_dialog(variant)
          choose_switch_target(target)
          apply_switch
        end

        def open_switch_dialog(variant)
          open_type_menu(variant)
          click_on "Use in this project"

          expect(switch_dialog).to have_select("Variant")
        end

        # The type's own menu, not one of the variant rows below it: both live inside the group.
        def open_type_menu(variant)
          within(find_row(variant)) { find(".op-border-box-list-header action-menu > button").click }
        end

        def choose_switch_target(target)
          within(switch_dialog) { select target, from: "Variant" }
        end

        def apply_switch
          within(switch_dialog) { click_on "Apply" }
        end

        def expect_switch_impact(text)
          expect(page.find("[data-test-selector='project-types-switch-impact']")).to have_text(text)
        end

        def expect_no_switch_impact
          expect(page.find("[data-test-selector='project-types-switch-impact']")).to have_no_text(/\S/)
        end

        def switch_dialog
          page.find_by_id("project-types-switch-dialog")
        end

        def expect_no_switch_action(variant)
          open_type_menu(variant)

          # Scoped to the group: another type's menu carries the same item, hidden until opened.
          expect(find_row(variant)).to have_no_text("Use in this project")
        end

        def find_row(variant)
          page.find("[data-test-selector='project-types-row-#{variant.id}']")
        end
      end
    end
  end
end

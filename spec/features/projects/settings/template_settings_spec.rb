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

require "spec_helper"

RSpec.describe "Projects", "template settings", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:role_to_exclude) { create(:project_role, name: "Template Manager") }
  shared_let(:role_to_keep) { create(:project_role, name: "Developer") }

  current_user { admin }

  describe "for a non-template project" do
    let(:project) { create(:project, templated: false) }

    it "shows a toggle switch to enable template mode" do
      visit project_settings_template_path(project)

      expect(page).to have_text(I18n.t("project.template.make_template"))
      expect(page).to have_css(".ToggleSwitch-statusOff")

      find(".ToggleSwitch-track").click

      expect(page).to have_css(".ToggleSwitch-statusOn")
      expect(project.reload).to be_templated
      expect(page).to have_text("Roles to exclude when template is applied")
    end
  end

  describe "for a template project" do
    let(:project) { create(:project, templated: true) }

    it "allows selecting roles to exclude when copying" do
      visit project_settings_template_path(project)

      expect(page).to have_css(".ToggleSwitch-statusOn")
      expect(page).to have_text("Roles to exclude when template is applied")

      autocomplete_field = page.find("[data-test-selector='excluded_role_ids']")
      select_autocomplete(autocomplete_field, query: role_to_exclude.name)

      click_button "Save"

      expect_and_dismiss_flash(message: "Successful update")

      project.reload
      expect(project.excluded_role_ids_on_copy).to contain_exactly(role_to_exclude.id)
      expect(page).to have_css(".ng-value-label", text: role_to_exclude.name)
    end

    it "allows selecting multiple roles and clearing the selection" do
      visit project_settings_template_path(project)

      autocomplete_field = page.find("[data-test-selector='excluded_role_ids']")

      select_autocomplete(autocomplete_field, query: role_to_exclude.name)
      select_autocomplete(autocomplete_field, query: role_to_keep.name)

      click_button "Save"

      expect_and_dismiss_flash(message: "Successful update")

      project.reload
      expect(project.excluded_role_ids_on_copy).to contain_exactly(role_to_exclude.id, role_to_keep.id)

      ng_select_clear(autocomplete_field)
      click_button "Save"

      expect_and_dismiss_flash(message: "Successful update")

      project.reload
      expect(project.excluded_role_ids_on_copy).to be_empty
    end
  end

  describe "permissions" do
    let(:project) { create(:project, templated: true) }

    context "when user is not an admin" do
      let(:user) { create(:user, member_with_permissions: { project => %i[edit_project] }) }
      let(:non_template) do
        create(:project,
               templated: false,
               members: { user => create(:project_role, permissions: %i[edit_project]) })
      end

      current_user { user }

      it "shows the toggle switch but cannot enable template mode" do
        visit project_settings_template_path(non_template)

        expect(page).to have_text(I18n.t("project.template.make_template"))
        expect(page).to have_css(".ToggleSwitch-statusOff")

        find(".ToggleSwitch-track").click

        expect_flash(type: :error, message: "Template project may not be accessed.")
        expect(non_template.reload).not_to be_templated
      end
    end
  end
end

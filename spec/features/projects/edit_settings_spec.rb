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

require "spec_helper"

RSpec.describe "Projects", "editing settings", :js do
  include_context "ng-select-autocomplete helpers"

  let(:permissions) { %i(edit_project view_project_attributes edit_project_attributes) }
  let(:project_memberships) { { project => permissions } }

  current_user do
    create(:user, member_with_permissions: project_memberships)
  end

  shared_let(:project) do
    create(:project, name: "Foo project", identifier: "foo-project")
  end

  it "hides the field whose functionality is presented otherwise" do
    visit project_settings_general_path(project.id)

    expect(page).to have_no_text :all, "Active"
  end

  describe "identifier edit" do
    context "with classic IDs", with_settings: { work_packages_identifier: "classic" } do
      it "updates the project identifier via dialog" do
        visit project_settings_general_path(project)

        click_on "Change identifier"

        expect(page).to have_dialog "Change project identifier"

        within "dialog" do
          expect(page).to have_text "This will permanently change identifiers and URLs"
          fill_in "project[identifier]", with: "foo-bar"
          click_on "Change identifier"
        end

        expect(page).to have_content "Successful update."
        expect(page).to have_current_path %r{/projects/foo-bar/settings/general}
        expect(project.reload.identifier).to eq "foo-bar"
      end
    end

    context "with semantic IDs", with_settings: { work_packages_identifier: "semantic" } do
      it "updates the project identifier via dialog" do
        visit project_settings_general_path(project)

        click_on "Change identifier"

        expect(page).to have_dialog "Change project identifier"

        within "dialog" do
          expect(page).to have_text "This will permanently change identifiers and URLs"
          fill_in "project[identifier]", with: "FOOBAR"
          click_on "Change identifier"
        end

        expect(page).to have_content "Successful update."
        expect(page).to have_current_path %r{/projects/FOOBAR/settings/general}
        expect(project.reload.identifier).to eq "FOOBAR"
      end

      it "displays an error when the identifier does not start with a letter" do
        visit project_settings_general_path(project)

        click_on "Change identifier"

        expect(page).to have_dialog "Change project identifier"

        within "dialog" do
          fill_in "project[identifier]", with: "123ABC"
          click_on "Change identifier"

          expect(page).to have_text "Identifier must start with a letter"
        end
      end

      it "displays an error when the identifier contains special characters" do
        visit project_settings_general_path(project)

        click_on "Change identifier"

        expect(page).to have_dialog "Change project identifier"

        within "dialog" do
          fill_in "project[identifier]", with: "FOO@BAR"
          click_on "Change identifier"

          expect(page).to have_text "Identifier may only contain uppercase letters, numbers, and underscores"
        end
      end
    end
  end

  describe "editing basic details" do
    before do
      Pages::Projects::Settings::General.new(project).visit!
    end

    it "updates the basic details" do
      within_section "Basic details" do
        fill_in "Name", with: "Bar project"
        fill_in_rich_text "Description", with: "a long and verbose project description."

        click_on "Update details"
      end

      expect_and_dismiss_flash type: :success, message: "Successful update."

      within_section "Basic details" do
        expect(page).to have_field "Name", with: "Bar project"
        expect(page).to have_selector :rich_text, "Description", text: "a long and verbose project description."
      end
    end

    it "displays validation error on invalid input" do
      within_section "Basic details" do
        fill_in "Name", with: ""
        click_on "Update details"

        expect(page).to have_field "Name", with: "", validation_error: "Name can't be blank."

        fill_in "Name", with: "A" * 256
        click_on "Update details"

        expect(page).to have_field "Name", with: "A" * 256, validation_error: "Name is too long (maximum is 255 characters)."
      end
    end
  end

  describe "editing status" do
    before do
      Pages::Projects::Settings::General.new(project).visit!
    end

    it "sets the project status" do
      within_section "Status" do
        click_on "Edit status"

        within :menu, "Edit status" do
          find(:menuitem, "Not started").click
        end
      end

      expect_and_dismiss_flash type: :success, message: "Successful update."

      within_section "Status" do
        button = find_button("Edit status")
        expect(button).to have_text "Not started"
        button.click

        expect(find(:menu, "Edit status")).to have_selector :menuitem, "Not started", aria: { current: true }
      end
    end

    it "unsets the project status" do
      within_section "Status" do
        click_on "Edit status"

        within :menu, "Edit status" do
          find(:menuitem, "Finished").click
        end
      end

      expect_and_dismiss_flash type: :success, message: "Successful update."

      within_section "Status" do
        click_on "Edit status"

        within :menu, "Edit status" do
          find(:menuitem, "Not set").click
        end
      end

      expect_and_dismiss_flash type: :success, message: "Successful update."

      within_section "Status" do
        button = find_button("Edit status")
        expect(button).to have_text "Not set"
        button.click

        expect(find(:menu, "Edit status")).to have_selector :menuitem, "Not set", aria: { current: true }
      end
    end

    it "updates the project status description" do
      within_section "Status" do
        fill_in_rich_text "Status description", with: "Light-years behind 🥺"

        click_on "Update status description"
      end

      expect_and_dismiss_flash type: :success, message: "Successful update."

      within_section "Status" do
        expect(page).to have_selector :rich_text, "Status description", text: "Light-years behind 🥺"
      end
    end
  end

  describe "editing project relations" do
    let(:parent_field) { FormFields::SelectFormField.new :parent }
    let(:parent_project) { create(:project, name: "New parent project") }

    before do
      project.update_attribute(:parent, parent_project)
    end

    context "with a user allowed to see parent project" do
      current_user { create(:user, member_with_permissions: { project => permissions, parent_project => permissions }) }

      it "updates the parent project" do
        Pages::Projects::Settings::General.new(project).visit!

        within_section "Project relations" do
          parent_field.expect_selected "New parent project"
          click_on "Update parent project"
        end

        expect_and_dismiss_flash type: :success, message: "Successful update."

        within_section "Project relations" do
          parent_field.expect_selected "New parent project"
        end
      end
    end

    context "with a user not allowed to see the parent project" do
      it "can update the project without destroying the relation to the parent" do
        Pages::Projects::Settings::General.new(project).visit!

        within_section "Project relations" do
          parent_field.expect_selected I18n.t(:"api_v3.undisclosed.parent")
          click_on "Update parent project"
        end

        expect_and_dismiss_flash type: :success, message: "Successful update."

        project.reload
        expect(project.parent).to eq parent_project
      end
    end
  end

  describe "attribute help texts" do
    let(:general_page) { Pages::Projects::Settings::General.new(project) }

    context "without attribute help texts defined" do
      before do
        general_page.visit!
      end

      it "shows field labels without help text link" do
        general_page.expect_field_label_without_help_text "Name"
        general_page.expect_field_label_without_help_text "Description"
        general_page.expect_field_label_without_help_text "Status description"
        general_page.expect_field_label_without_help_text "Subproject of"
      end

      it "does not show help text link next to status button" do
        within_section "Status" do
          button = find_button("Edit status")
          expect(page).to have_no_link accessible_name: "Show help text", right_of: button
        end
      end
    end

    context "with attribute help texts defined" do
      let!(:name_help_text) { create(:project_help_text, attribute_name: :name) }
      let!(:description_help_text) { create(:project_help_text, attribute_name: :description) }
      let!(:status_help_text) { create(:project_help_text, attribute_name: :status) }
      let!(:status_description_help_text) { create(:project_help_text, attribute_name: :status_explanation) }
      let!(:subproject_of_help_text) { create(:project_help_text, attribute_name: :parent) }

      before do
        general_page.visit!
      end

      it "shows field labels with help text link" do
        general_page.expect_field_label_with_help_text "Name"
        general_page.expect_field_label_with_help_text "Description"
        general_page.expect_field_label_with_help_text "Status description"
        general_page.expect_field_label_with_help_text "Subproject of"
      end

      it "shows help text link next to status button", :selenium do
        within_section "Status" do
          button = find_button("Edit status")
          expect(page).to have_link accessible_name: "Show help text", right_of: button
        end
      end

      it "shows help text modal on clicking help text link" do
        general_page.click_help_text_link_for_label "Description"

        expect(page).to have_modal "Description"
        within_modal "Description" do
          expect(page).to have_text "Attribute help text"

          click_on "Close"
        end
        expect(page).to have_no_modal "Description"
      end
    end
  end

  describe "workspace type badges in Subproject of field" do
    shared_let(:portfolio) { create(:portfolio, name: "Parent Portfolio") }
    shared_let(:program) { create(:program, name: "Parent Program") }
    shared_let(:regular_project) { create(:project, name: "Regular Project") }
    let(:parent_permissions) { %i[add_subprojects] }

    let(:project_memberships) do
      { project => permissions,
        portfolio => parent_permissions,
        program => parent_permissions,
        regular_project => parent_permissions }
    end

    it "displays workspace type badges for portfolios and programs" do
      general_page = Pages::Projects::Settings::General.new(project)
      general_page.visit!

      parent_field = general_page.parent_project_field

      # Verify badges for different project types
      parent_field.expect_option("Parent Portfolio", workspace_badge: "Portfolio")
      parent_field.expect_option("Parent Program", workspace_badge: "Program")
      parent_field.expect_option("Regular Project")
    end
  end
end

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

RSpec.describe "Projects", "creation", :js do
  shared_let(:project_custom_field_section) { create(:project_custom_field_section, name: "Section A") }

  current_user { create(:admin) }

  shared_let(:project) { create(:project, name: "Foo project", identifier: "foo-project") }

  let(:projects_page) { Pages::Projects::Index.new }

  before do
    projects_page.visit!
  end

  context "with the button on the toolbar items" do
    it "can navigate to the create project page" do
      projects_page.create_new_workspace :project, open_menu: true

      expect(page).to have_heading "New project"

      expect(page).to have_current_path(new_project_path)
    end
  end

  it "can create a project" do
    projects_page.create_new_workspace :project, open_menu: true

    expect(page).to have_heading "New project"

    # Step 1: Select workspace type (blank project)
    click_on "Continue"

    # Step 2: Fill in project details
    expect(page).to have_text("2 of 2")
    fill_in "Name", with: "Foo bar"
    click_on "Complete"

    expect_and_dismiss_flash type: :success, message: "Successful creation."

    expect(page).to have_current_path /\/projects\/foo-bar\/?/
    expect(page).to have_content "Foo bar"
  end

  it "redirects to the parent project page when users cancels while creating subproject" do
    # Go to parent project page
    visit project_overview_path(project.id)

    # Start creating a subproject from parent context
    page.find_test_selector("quick-add-menu-button").click
    page.find_test_selector("quick-add-menu-item", text: "Project", wait: 5).click

    expect(page).to have_heading "New project"

    click_on "Cancel"

    expect(page).to have_current_path project_overview_path(project.id)
  end

  it "redirects to projects#index when users cancels" do
    visit new_project_path

    expect(page).to have_heading "New project"

    click_on "Cancel"
    expect(page).to have_current_path projects_path
  end

  it "redirects to the parent project page when users press the close icon while creating subproject" do
    # Go to parent project page
    visit project_overview_path(project.id)

    # Start creating a subproject from parent context
    page.find_test_selector("quick-add-menu-button").click
    page.find_test_selector("quick-add-menu-item", text: "Project", wait: 5).click

    expect(page).to have_heading "New project"

    # Click the close (X) icon in the header
    find_test_selector("new_project_form_close_icon").click

    expect(page).to have_current_path project_overview_path(project.id)
  end

  it "redirects to projects#index when users click on close icon" do
    visit new_project_path

    expect(page).to have_heading "New project"

    find_test_selector("new_project_form_close_icon").click
    expect(page).to have_current_path projects_path
  end

  it "does not create a project with an already existing identifier" do
    projects_page.create_new_workspace :project, open_menu: true

    expect(page).to have_heading "New project"

    # Step 1: Select workspace type (blank project)
    click_on "Continue"

    # Step 2: Fill in project details
    fill_in "Name", with: "Foo project"
    click_on "Complete"

    expect_and_dismiss_flash type: :success, message: "Successful creation."

    expect(page).to have_current_path /\/projects\/foo-project-1\/?/

    project = Project.last
    expect(project.identifier).to eq "foo-project-1"
  end

  it "does not create a project when the name is not present" do
    projects_page.create_new_workspace :project, open_menu: true

    expect(page).to have_heading "New project"

    # Step 1: Select workspace type (blank project)
    click_on "Continue"

    # Step 2: Try to complete without name
    expect(page).to have_text("2 of 2")
    click_on "Complete"

    expect_and_dismiss_flash type: :error, message: /^Creation failed/

    expect(page).to have_text("2 of 2")
    expect(page).to have_field "Name", validation_error: "can't be blank."
  end

  context "with a multi-select list custom field" do
    shared_let(:list_custom_field) do
      create(:list_project_custom_field,
             name: "List CF",
             is_required: true,
             is_for_all: true,
             multi_value: true,
             project_custom_field_section:)
    end
    let(:list_field) do
      FormFields::SelectFormField.new(
        list_custom_field,
        selector: "[data-test-selector='#{list_custom_field.attribute_name(:kebab_case)}'"
      )
    end

    it "can create a project" do
      projects_page.create_new_workspace :project, open_menu: true

      expect(page).to have_heading "New project"

      # Step 1: Select workspace type (blank project)
      click_on "Continue"

      # Step 2: Fill in project details
      expect(page).to have_text("2 of 3")
      fill_in "Name", with: "Foo bar"
      click_on "Continue"

      # Step 3: Fill in custom fields
      expect(page).to have_text("3 of 3")
      expect(page).to have_combo_box "List CF *"
      list_field.select_option "A", "B"

      click_on "Complete"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      expect(page).to have_current_path /\/projects\/foo-bar\/?/
      expect(page).to have_content "Foo bar"

      project = Project.last
      expect(project.name).to eq "Foo bar"
      cvs = project.custom_value_for(list_custom_field)
      expect(cvs.count).to eq 2
      expect(cvs.map(&:typed_value)).to contain_exactly "A", "B"
    end
  end

  context "with a multi-select version custom field" do
    include_context "ng-select-autocomplete helpers"

    shared_let(:public_project) do
      create(:project, name: "Public Pr", identifier: "public-pr", public: true)
    end

    shared_let(:versions) do
      [
        create(:version, project:, name: "Ringbo 1.0", sharing: "system"),
        create(:version, project: public_project, name: "Ringbo 2.0", sharing: "system")
      ]
    end

    shared_let(:version_custom_field) do
      create(:version_project_custom_field,
             name: "Version CF",
             is_required: true,
             is_for_all: true,
             multi_value: true,
             project_custom_field_section:)
    end

    let(:version_field) do
      FormFields::SelectFormField.new(
        version_custom_field,
        selector: "[data-test-selector='#{version_custom_field.attribute_name(:kebab_case)}'"
      )
    end

    it "can create a project" do
      projects_page.create_new_workspace :project, open_menu: true

      expect(page).to have_heading "New project"

      # Step 1: Select workspace type (blank project)
      click_on "Continue"

      # Step 2: Fill in project details
      expect(page).to have_text("2 of 3")
      fill_in "Name", with: "Foo bar"
      click_on "Continue"

      # Step 3: Fill in custom fields
      expect(page).to have_text("3 of 3")
      expect(page).to have_combo_box "Version CF *"

      # expect the versions are grouped by the project name
      version_field.expect_option(versions.first.name, grouping: project.name)
      version_field.expect_option(versions.last.name, grouping: public_project.name)

      version_field.select_option(versions.first.name, versions.last.name)

      click_on "Complete"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      expect(page).to have_current_path /\/projects\/foo-bar\/?/
      expect(page).to have_content "Foo bar"

      project = Project.last
      expect(project.name).to eq "Foo bar"

      typed_values = project.custom_value_for(version_custom_field).map(&:typed_value)
      expect(typed_values).to eq versions
    end
  end

  it "hides the active field and the identifier" do
    visit new_project_path

    expect(page).to have_heading "New project"

    expect(page).to have_no_content "Active"
    expect(page).to have_no_content "Identifier"
  end

  context "with optional and required custom fields" do
    shared_let(:optional_custom_field) do
      create(:project_custom_field, name: "Optional Foo",
                                    field_format: "string",
                                    is_for_all: true,
                                    project_custom_field_section:)
    end
    shared_let(:required_custom_field) do
      create(:project_custom_field, name: "Required Foo",
                                    field_format: "string",
                                    is_for_all: true,
                                    is_required: true,
                                    project_custom_field_section:)
    end

    context "with required custom fields" do
      shared_let(:required_user_custom_field) do
        create(:user_project_custom_field, name: "Required User",
                                           is_for_all: true,
                                           is_required: true,
                                           project_custom_field_section:)
      end

      shared_let(:required_but_inactive_custom_field) do
        create(:text_project_custom_field,
               name: "Required inactive",
               is_required: true,
               project_custom_field_section:)
      end

      shared_let(:required_inactive_custom_field_with_default_value) do
        create(:text_project_custom_field,
               name: "Required inactive with default value",
               is_required: true,
               default_value: "foo",
               project_custom_field_section:)
      end

      it "renders activated required custom fields for new" do
        visit new_project_path

        expect(page).to have_heading "New project"

        # Step 1: Select workspace type (blank project)
        click_on "Continue"

        # Step 2: Project details - skip to step 3
        expect(page).to have_text("2 of 3")
        fill_in "Name", with: "Test Project"
        click_on "Continue"

        # Step 3: Custom fields
        expect(page).to have_text("3 of 3")
        expect(page).to have_field "Required Foo *"
        expect(page).to have_field "Required User *"

        # Optional fields should not be shown
        expect(page).to have_no_field "Optional Foo"

        # Inactive fields, even if required, should not be shown
        expect(page).to have_no_field "Required Inactive *"
        expect(page).to have_no_field "Required Inactive with default value *"
      end
    end

    context "with correct validations" do
      before do
        visit new_project_path
      end

      it "requires the required custom field" do
        expect(page).to have_heading "New project"

        # Step 1: Select workspace type (blank project)
        click_on "Continue"

        # Step 2: Fill in name
        expect(page).to have_text("2 of 3")
        fill_in "Name", with: "Test Project"
        click_on "Continue"

        # Step 3: Try to complete without required custom field
        expect(page).to have_text("3 of 3")
        click_on "Complete"

        expect_and_dismiss_flash type: :error, message: /^Creation failed/

        expect(page).to have_text("3 of 3")
        expect(page).to have_field "Required Foo *", validation_error: "can't be blank."
      end
    end

    context "with correct custom field activation" do
      shared_let(:unused_custom_field) do
        create(:project_custom_field, name: "Unused Foo",
                                      field_format: "string",
                                      project_custom_field_section:)
      end

      before do
        visit new_project_path

        expect(page).to have_heading "New project" # rubocop:disable RSpec/ExpectInHook

        # Step 1: Select workspace type
        click_on "Continue"

        # Step 2: Fill in project details
        fill_in "Name", with: "Foo bar"
        click_on "Continue"

        # Step 3: Fill in required custom field
        fill_in "Required Foo", with: "Required value"
      end

      it "enables custom fields with provided values and for_all fields for this project" do
        click_on "Complete"

        expect_and_dismiss_flash type: :success, message: "Successful creation."

        expect(page).to have_current_path /\/projects\/foo-bar\/?/

        project = Project.last

        # unused custom field should not be activated
        expect(project.project_custom_field_ids).to contain_exactly(
          required_custom_field.id, optional_custom_field.id
        )
      end

      context "with correct handling of default values" do
        shared_let(:custom_field_with_default_value) do
          create(:project_custom_field, name: "Foo with default value",
                                        field_format: "string",
                                        is_required: true,
                                        is_for_all: true,
                                        default_value: "Default value",
                                        project_custom_field_section:)
        end

        it "enables custom fields with default values if not set to blank explicitly" do
          # don't touch the default value
          wait_for_turbo { click_on "Complete" }

          expect_and_dismiss_flash type: :success, message: "Successful creation."

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          project = Project.last

          # custom_field_with_default_value should be activated and contain the default value
          expect(project.project_custom_field_ids).to contain_exactly(
            custom_field_with_default_value.id, required_custom_field.id, optional_custom_field.id
          )

          expect(project.custom_value_for(custom_field_with_default_value).value).to eq("Default value")
        end

        it "does enable custom fields with default values if overwritten with a new value" do
          fill_in "Foo with default value", with: "foo"

          click_on "Complete"

          expect(page).to have_current_path /\/projects\/foo-bar\/?/

          expect_and_dismiss_flash type: :success, message: "Successful creation."

          project = Project.last

          # custom_field_with_default_value should be activated and contain the overwritten value
          expect(project.project_custom_field_ids).to contain_exactly(
            custom_field_with_default_value.id, required_custom_field.id, optional_custom_field.id
          )

          expect(project.custom_value_for(custom_field_with_default_value).value).to eq("foo")
        end
      end

      context "with correct handling of invisible values" do
        shared_let(:invisible_field) do
          create(:string_project_custom_field, name: "Text for Admins only",
                                               is_required: true,
                                               is_for_all: true,
                                               admin_only: true,
                                               project_custom_field_section:)
        end

        context "with an admin user" do
          it "shows invisible fields in the form and allows their activation" do
            expect(page).to have_content "Text for Admins only"

            fill_in "Text for Admins only", with: "foo"

            click_on "Complete"

            expect_and_dismiss_flash type: :success, message: "Successful creation."

            expect(page).to have_current_path /\/projects\/foo-bar\/?/

            project = Project.last

            expect(project.project_custom_field_ids).to contain_exactly(
              required_custom_field.id, optional_custom_field.id, invisible_field.id
            )

            expect(project.custom_value_for(invisible_field).typed_value).to eq("foo")
          end
        end

        context "with a non-admin user" do
          current_user { create(:user, global_permissions: %i[add_project]) }

          it "does not show invisible fields in the form and thus not activates the invisible field" do
            pending "Admin-only project attributes currently prevent users from creating projects (OP#64479)"

            expect(page).to have_no_content "Text for Admins only"

            click_on "Complete"

            expect_and_dismiss_flash type: :success, message: "Successful creation."

            expect(page).to have_current_path /\/projects\/foo-bar\/?/

            project = Project.last

            expect(project.project_custom_field_ids).to contain_exactly(
              required_custom_field.id, optional_custom_field.id
            )
          end
        end
      end
    end
  end

  context "with a required custom field that is not for all projects" do
    shared_let(:required_not_for_all_custom_field) do
      create(:project_custom_field, name: "Required not for all",
                                    field_format: "string",
                                    is_required: true,
                                    is_for_all: false,
                                    project_custom_field_section:)
    end

    it "does not show the project attributes step" do
      projects_page.create_new_workspace :project, open_menu: true

      expect(page).to have_heading "New project"

      # Step 1: Select workspace type (blank project)
      click_on "Continue"

      # Step 2: Fill in project details
      # Should show "2 of 2" because the required field is not for all projects
      # The bug causes this to show "2 of 3" incorrectly
      expect(page).to have_text("2 of 2")
      fill_in "Name", with: "Project without step 3"

      # Should have Complete button (not Continue) since this is the last step
      expect(page).to have_button("Complete")
      expect(page).to have_no_button("Continue")

      click_on "Complete"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      expect(page).to have_current_path %r{/projects/project-without-step-3/?}
      expect(page).to have_content "Project without step 3"

      # The required_not_for_all field should NOT be activated for the new project
      new_project = Project.find_by(name: "Project without step 3")
      expect(new_project.project_custom_field_ids).not_to include(required_not_for_all_custom_field.id)
    end
  end

  context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
    it "auto-suggests an identifier when the name field is blurred" do
      projects_page.create_new_workspace :project, open_menu: true
      click_on "Continue"

      fill_in "Name", with: "Flight Planning Algorithm"
      find("body").click # blur the name field

      expect(page).to have_field "Identifier", with: "FPA"
    end

    it "allows overriding the auto-suggested identifier" do
      projects_page.create_new_workspace :project, open_menu: true
      click_on "Continue"

      fill_in "Name", with: "Flight Planning Algorithm"
      find("body").click
      expect(page).to have_field "Identifier", with: "FPA"

      fill_in "Identifier", with: "MYIDENT"
      click_on "Complete"

      expect_and_dismiss_flash type: :success, message: "Successful creation."
      expect(page).to have_current_path %r{/projects/MYIDENT/?}
    end

    it "shows a validation error for identifiers not starting with a letter" do
      projects_page.create_new_workspace :project, open_menu: true
      click_on "Continue"

      fill_in "Name", with: "Flight Planning Algorithm"
      find("body").click
      expect(page).to have_field "Identifier", with: "FPA"

      expect(page).to have_field "Identifier", with: "FPA"
      fill_in "Identifier", with: "3INVALID"
      click_on "Complete"

      expect(page).to have_text "Identifier must start with a letter"
    end
  end

  context "with workspace type badges in parent field" do
    include_context "ng-select-autocomplete helpers"

    shared_let(:portfolio) { create(:portfolio, name: "Parent Portfolio") }
    shared_let(:program) { create(:program, name: "Parent Program") }

    it "displays workspace type badges for portfolios and programs in the parent field" do
      visit new_project_path

      # Step 1: Select workspace type (blank project)
      click_on "Continue"

      # Step 2: Fill in project details
      fill_in "Name", with: "Test Subproject"

      # Open parent field autocompleter
      expect(page).to have_combo_box "Subproject of"
      parent_autocompleter = page.find("opce-project-autocompleter")

      # Search for portfolio
      dropdown = search_autocomplete(parent_autocompleter,
                                     query: "Portfolio",
                                     results_selector: ".ng-dropdown-panel-items")

      within(dropdown) do
        expect(page).to have_text("Portfolio")
        expect(page).to have_css("svg.octicon")
      end

      # Clear and search for program
      parent_autocompleter.find("input").set("")

      dropdown = search_autocomplete(parent_autocompleter,
                                     query: "Program",
                                     results_selector: ".ng-dropdown-panel-items")

      within(dropdown) do
        expect(page).to have_text("Program")
        expect(page).to have_css("svg.octicon")
      end

      # Clear and search for regular project - should not have workspace type badge
      parent_autocompleter.find("input").set("")

      dropdown = search_autocomplete(parent_autocompleter,
                                     query: "Foo project",
                                     results_selector: ".ng-dropdown-panel-items")

      within(dropdown) do
        expect(page).to have_text("Foo project")
        expect(page).to have_no_css("svg.octicon")
      end
    end
  end
end

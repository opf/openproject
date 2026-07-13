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

# This is a feature spec for the project creation wizard, but only when creating
# a new project from a template with the wizard enabled (Project Initiation Request, PIR).
# The wizard that is shown when creating a new blank project from scratch is NOT tested here.
# See `spec/features/projects/create_spec.rb` for that.
RSpec.describe "Project creation wizard",
               :js,
               :with_cuprite do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }

  shared_let(:section1) do
    create(:project_custom_field_section, name: "Basic Information")
  end

  shared_let(:section2) do
    create(:project_custom_field_section, name: "Project Details")
  end

  shared_let(:text_custom_field) do
    create(:text_project_custom_field,
           name: "Project Description",
           project_custom_field_section: section1)
  end

  shared_let(:string_custom_field) do
    create(:string_project_custom_field,
           name: "Project Code",
           project_custom_field_section: section1)
  end

  shared_let(:list_custom_field) do
    create(:list_project_custom_field,
           name: "Project Type",
           project_custom_field_section: section2,
           possible_values: %w[Internal External Research])
  end

  shared_let(:user_custom_field) do
    create(:user_project_custom_field,
           name: "Project Validator",
           project_custom_field_section: section2)
  end

  shared_let(:int_custom_field) do
    create(:integer_project_custom_field,
           name: "Team Size",
           project_custom_field_section: section2)
  end

  shared_let(:help_text_description) do
    create(:project_help_text,
           attribute_name: "custom_field_#{text_custom_field.id}",
           help_text: "Enter a detailed description of your project goals and objectives.")
  end

  shared_let(:help_text_code) do
    create(:project_help_text,
           attribute_name: "custom_field_#{string_custom_field.id}",
           help_text: "Use a unique code to identify this project (e.g., PROJ-001).")
  end

  shared_let(:help_text_type) do
    create(:project_help_text,
           attribute_name: "custom_field_#{list_custom_field.id}",
           help_text: "Select the type that best describes your project.")
  end

  shared_let(:user_assignee) do
    create(:user, firstname: "user_assignee")
  end

  shared_let(:project) do
    status_new = create(:status, name: "New")
    status_in_progress = create(:status, name: "In Progress")
    type = create(:type, name: "Project initiation")
    role = create(:project_role, permissions: %i[view_project_attributes add_work_packages work_package_assigned])
    create(:workflow, type:, role:, old_status: status_new, new_status: status_in_progress)
    create(:default_priority)
    create(:project,
           name: "Test Project",
           types: [type],
           project_custom_fields: [user_custom_field],
           project_creation_wizard_enabled: true,
           project_creation_wizard_work_package_type_id: type.id,
           project_creation_wizard_status_when_submitted_id: status_new.id,
           project_creation_wizard_assignee_custom_field_id: user_custom_field.id).tap do |prj|
             prj.members << create(:member, principal: user_assignee, project: prj, roles: [role])
           end
  end
  let(:wizard_path) { "/projects/#{project.identifier}/creation_wizard" }
  let(:text_field_editor) do
    Components::WysiwygEditor.new "[data-test-selector='custom-field-#{text_custom_field.id}']"
  end

  current_user { admin }

  before do
    # Enable custom fields for the project
    create(:project_custom_field_project_mapping, project:, project_custom_field: text_custom_field)
    create(:project_custom_field_project_mapping, project:, project_custom_field: string_custom_field)
    create(:project_custom_field_project_mapping, project:, project_custom_field: list_custom_field)
    create(:project_custom_field_project_mapping, project:, project_custom_field: int_custom_field)
  end

  it "can visit the wizard path manually and navigate through sections" do
    visit wizard_path

    # Should show the wizard page with the first section
    expect(page).to have_css("h3", text: "Basic Information")
    expect(page).to have_text("Project Description")
    expect(page).to have_text("Project Code")

    # Should show progress bar with correct section count
    expect(page).to have_text("1 of 2")

    # Should show the sections in the sidebar
    within(".op-projects-wizard") do
      expect(page).to have_link("Basic Information")
      expect(page).to have_link("Project Details")
    end

    # Should have Continue button but no Back button on first page
    expect(page).to have_button("Continue")
    expect(page).to have_no_button("Back")

    # Should have Cancel button
    expect(page).to have_link("Cancel")
  end

  it "shows different sections as separate pages" do
    visit wizard_path

    # First section
    expect(page).to have_css("h3", text: "Basic Information")
    expect(page).to have_text("Project Description")
    expect(page).to have_text("Project Code")
    expect(page).to have_no_text("Project Type")
    expect(page).to have_no_text("Team Size")
    expect(page).to have_button("Continue")

    # Navigate to second section via sidebar
    click_link "Project Details"

    # Second section
    expect(page).to have_css("h3", text: "Project Details")
    expect(page).to have_text("Project Type")
    expect(page).to have_text("Team Size")
    expect(page).to have_no_text("Project Description")
    expect(page).to have_no_text("Project Code")

    # Should show Back button on second page
    expect(page).to have_link("Back")
    expect(page).to have_no_button("Next")
    expect(page).to have_button("Complete")

    # Progress should show section 2 of 2
    expect(page).to have_text("2 of 2")
  end

  it "displays and updates attribute help texts when focusing different fields" do
    visit wizard_path

    # Initially, help text for the first field should be visible
    expect(page).to have_text("Enter a detailed description of your project goals and objectives.")

    # Focus on Project Code field
    retry_block do
      code_field = find_field("Project Code")
      code_field.click

      # Help text should change
      expect(page).to have_text("Use a unique code to identify this project (e.g., PROJ-001).", wait: 5)
      expect(page).to have_no_text("Enter a detailed description")
    end

    # Navigate to second section
    click_link "Project Details"

    # Focus on Project Type field
    type_field = find_field("Project Type")
    type_field.click

    # Help text should update to show type help text
    expect(page).to have_text("Select the type that best describes your project.", wait: 5)
    expect(page).to have_no_text("Use a unique code")
  end

  it "updates and persists field values when clicking next" do
    visit wizard_path

    # Fill in fields in first section (Project Description is a textarea)
    text_field_editor.set_markdown "This is a test project for validation"
    fill_in "Project Code", with: "TEST-001"

    # Click Continue to go to next section
    click_button "Continue"

    # Should be on second section now
    expect(page).to have_css("h3", text: "Project Details")
    expect(page).to have_text("2 of 2")

    # Fill in fields in second section
    select_autocomplete page.find("[data-custom-field-id='#{list_custom_field.id}']"),
                        results_selector: "body",
                        query: "External"
    fill_in "Team Size", with: "5"

    click_link "Back"

    # Should be back on first section
    expect(page).to have_css("h3", text: "Basic Information")

    # Values should be persisted
    text_field_editor.expect_value("This is a test project for validation")
    expect(page).to have_field("Project Code", with: "TEST-001")
    click_button "Continue"

    # Should be on second section without persisted values
    expect(page).to have_css("h3", text: "Project Details")
    expect(page).to have_field("Team Size", with: "")

    select_autocomplete page.find("[data-custom-field-id='#{list_custom_field.id}']"),
                        results_selector: "body",
                        query: "Internal"
    select_autocomplete page.find("[data-custom-field-id='#{user_custom_field.id}']"),
                        results_selector: "body",
                        query: user_assignee.name
    fill_in "Team Size", with: "5"

    click_button "Complete"
    expect(page).to have_text("Project attributes saved and artifact work package created successfully.")

    project.reload
    expect(page).to have_current_path("/projects/#{project.identifier}/" \
                                      "work_packages/#{project.project_creation_wizard_artifact_work_package_id}/" \
                                      "activity")
    expect(project.typed_custom_value_for(text_custom_field)).to eq("This is a test project for validation")
    expect(project.typed_custom_value_for(string_custom_field)).to eq("TEST-001")
    expect(project.typed_custom_value_for(list_custom_field)).to eq("Internal")
    expect(project.typed_custom_value_for(int_custom_field)).to eq(5)
    expect(project.typed_custom_value_for(user_custom_field)).to eq(user_assignee)

    perform_enqueued_jobs

    work_package = WorkPackage.find(project.project_creation_wizard_artifact_work_package_id)
    expect(work_package.attachments.count).to eq(1)
  end

  it "shows completion checkmarks for sections with filled fields" do
    visit wizard_path

    # Initially, no checkmarks should be visible
    page.within(".op-projects-wizard--sidebar") do
      section_item = find("a", text: "Basic Information")
      expect(section_item).to be_present
      expect(section_item).to have_no_css(".octicon-check")
    end

    # Fill in all fields in first section
    text_field_editor.set_markdown "Complete description"
    fill_in "Project Code", with: "COMPLETE-001"

    # Click Continue
    click_button "Continue"
    expect(page).to have_css("h3", text: "Project Details")

    # First section should now show a checkmark
    # The checkmark icon should be present for the completed section
    page.within(".op-projects-wizard--sidebar") do
      section_item = find("a", text: "Basic Information")
      expect(section_item).to be_present
      expect(section_item).to have_css(".octicon-check")
    end
  end

  it "shows the correct last section behavior with Complete button" do
    visit wizard_path

    # Navigate to last section via sidebar
    click_link "Project Details"

    # Should be on last section
    expect(page).to have_css("h3", text: "Project Details")

    # Should show Complete instead of Continue
    expect(page).to have_button("Complete")
    expect(page).to have_no_button("Continue")

    # Should still have Back and Cancel buttons
    expect(page).to have_link("Back")
    expect(page).to have_link("Cancel")
  end

  it "can cancel and return to project overview" do
    visit wizard_path

    # Fill in some data
    fill_in "Project Code", with: "CANCEL-TEST"

    # Click Cancel (in the footer)
    within(".op-step-wizard-footer") do
      click_link "Cancel"
    end

    # Should redirect to project overview
    expect(page).to have_current_path("/projects/#{project.identifier}")

    # Data should not be saved
    project.reload
    expect(project.typed_custom_value_for(string_custom_field)&.value).to be_nil
  end

  context "when a custom field is disabled in the creation wizard" do
    let!(:disabled_custom_field) do
      create(:string_project_custom_field,
             name: "Disabled Field",
             project_custom_field_section: section1)
    end

    let!(:disabled_mapping) do
      create(:project_custom_field_project_mapping,
             project:,
             project_custom_field: disabled_custom_field,
             creation_wizard: false)
    end

    it "does not show the disabled custom field in the wizard" do
      visit wizard_path

      # Should show the enabled fields in section 1
      expect(page).to have_css("h3", text: "Basic Information")
      expect(page).to have_text("Project Description")
      expect(page).to have_text("Project Code")

      # Should NOT show the disabled field
      expect(page).to have_no_text("Disabled Field")
      expect(page).to have_no_field("Disabled Field")
    end

    it "still allows editing the project and does not affect enabled fields" do
      visit wizard_path

      # Fill in enabled fields
      text_field_editor.set_markdown "Test description"
      fill_in "Project Code", with: "TEST-ENABLED"

      click_button "Continue"
      click_link "Project Details"

      select_autocomplete page.find("[data-custom-field-id='#{list_custom_field.id}']"),
                          results_selector: "body",
                          query: "Internal"
      select_autocomplete page.find("[data-custom-field-id='#{user_custom_field.id}']"),
                          results_selector: "body",
                          query: user_assignee.name
      fill_in "Team Size", with: "3"

      click_button "Complete"

      expect(page).to have_text("Project attributes saved and artifact work package created successfully.")

      project.reload
      expect(page).to have_current_path("/projects/#{project.identifier}/" \
                                        "work_packages/#{project.project_creation_wizard_artifact_work_package_id}/" \
                                        "activity")
      expect(project.typed_custom_value_for(text_custom_field)).to eq("Test description")
      expect(project.typed_custom_value_for(string_custom_field)).to eq("TEST-ENABLED")
      expect(project.typed_custom_value_for(list_custom_field)).to eq("Internal")
      expect(project.typed_custom_value_for(int_custom_field)).to eq(3)
      expect(project.typed_custom_value_for(user_custom_field)).to eq(user_assignee)
    end
  end

  context "when all fields in a section are disabled in the creation wizard" do
    before do
      ProjectCustomFieldProjectMapping
        .where(project:, custom_field_id: [list_custom_field.id, user_custom_field.id, int_custom_field.id])
        .update_all(creation_wizard: false)
    end

    it "does not show the section with all disabled fields" do
      visit wizard_path

      # Should only show section 1
      expect(page).to have_css("h3", text: "Basic Information")
      expect(page).to have_text("Project Description")
      expect(page).to have_text("Project Code")

      # Should not show section 2 in the sidebar
      within(".op-projects-wizard--sidebar") do
        expect(page).to have_link("Basic Information")
        expect(page).to have_no_link("Project Details")
      end

      expect(page).to have_text("1 of 1")
      expect(page).to have_button("Complete")
      expect(page).to have_no_button("Continue")
    end
  end

  context "when user does not have edit_project_attributes permission" do
    current_user do
      create(:user, member_with_permissions: { project => %i[view_user] })
    end

    it "denies access to the wizard" do
      visit wizard_path

      # Should show an error message about lacking permissions
      expect(page).to have_text("You are not authorized to access this page")
    end
  end

  context "with comments enabled for custom fields" do
    before do
      string_custom_field.update!(has_comment: true, is_required: true)
    end

    it "remembers comment between page loads and saves it at the end" do
      visit wizard_path

      # Fill comment, but not required description
      fill_in "Project Code comment", with: "foo"
      click_button "Continue"
      wait_for_network_idle
      expect(page).to have_field("Project Code comment", with: "foo")

      # Also fill description and go to next page
      fill_in "Project Code", type: "text", with: "TEST-001"
      click_button "Continue"
      wait_for_network_idle
      expect(page).to have_no_field("Project Code comment")

      # Check if first page still has comment
      click_link "Back"
      wait_for_network_idle
      expect(page).to have_field("Project Code comment", with: "foo")

      # Finish the wizard
      click_button "Continue"
      wait_for_network_idle
      select_autocomplete page.find("[data-custom-field-id='#{user_custom_field.id}']"),
                          results_selector: "body",
                          query: user_assignee.name
      click_button "Complete"
      wait_for_network_idle

      # Comment should be saved
      expect(project.reload.send(string_custom_field.comment_attribute_name)).to eq "foo"
    end
  end
end

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

RSpec.describe "Project creation wizard settings - attributes tab",
               :js,
               :with_cuprite do
  let(:admin) { create(:admin) }
  let(:project) { create(:project, name: "Test Project", project_creation_wizard_enabled: true) }

  let!(:section1) { create(:project_custom_field_section, name: "Basic Information") }
  let!(:section2) { create(:project_custom_field_section, name: "Project Details") }

  let!(:text_custom_field) do
    create(:text_project_custom_field,
           name: "Project Description",
           project_custom_field_section: section1)
  end

  let!(:string_custom_field) do
    create(:string_project_custom_field,
           name: "Project Code",
           project_custom_field_section: section1)
  end

  let!(:list_custom_field) do
    create(:list_project_custom_field,
           name: "Project Type",
           project_custom_field_section: section2,
           possible_values: %w[Internal External])
  end

  let!(:int_custom_field) do
    create(:integer_project_custom_field,
           name: "Team Size",
           project_custom_field_section: section2)
  end

  let!(:required_int_custom_field) do
    create(:integer_project_custom_field,
           name: "Important number",
           is_required: true,
           project_custom_field_section: section2)
  end

  let!(:text_mapping) do
    create(:project_custom_field_project_mapping,
           project:,
           project_custom_field: text_custom_field,
           creation_wizard: true)
  end

  let!(:string_mapping) do
    create(:project_custom_field_project_mapping,
           project:,
           project_custom_field: string_custom_field,
           creation_wizard: false)
  end

  let!(:list_mapping) do
    create(:project_custom_field_project_mapping,
           project:,
           project_custom_field: list_custom_field,
           creation_wizard: true)
  end

  let!(:int_mapping) do
    create(:project_custom_field_project_mapping,
           project:,
           project_custom_field: int_custom_field,
           creation_wizard: true)
  end

  let!(:required_int_mapping) do
    create(:project_custom_field_project_mapping,
           project:,
           project_custom_field: required_int_custom_field,
           creation_wizard: true)
  end

  current_user { admin }

  before do
    visit project_settings_creation_wizard_path(project, tab: "attributes")
  end

  it "shows only sections that have active custom fields for the project" do
    expect(page).to have_text("Basic Information", wait: 10)
    expect(page).to have_text("Project Details")
  end

  it "shows only custom fields that are active for the project" do
    within_custom_field_section_container(section1) do
      expect(page).to have_text("Project Description")
      expect(page).to have_text("Project Code")
    end

    within_custom_field_section_container(section2) do
      expect(page).to have_text("Project Type")
      expect(page).to have_text("Team Size")
    end
  end

  it "shows custom fields with correct toggle states based on creation_wizard field" do
    within_custom_field_section_container(section1) do
      within_custom_field_container(text_custom_field) do
        expect_checked_state
      end

      within_custom_field_container(string_custom_field) do
        expect_unchecked_state
      end
    end

    within_custom_field_section_container(section2) do
      within_custom_field_container(list_custom_field) do
        expect_checked_state
      end

      within_custom_field_container(int_custom_field) do
        expect_checked_state
      end

      within_custom_field_container(required_int_custom_field) do
        expect_checked_state
      end
    end
  end

  it "toggles the creation_wizard field when clicking the toggle switch" do
    within_custom_field_section_container(section1) do
      within_custom_field_container(string_custom_field) do
        expect_unchecked_state

        page
          .find("[data-test-selector='toggle-creation-wizard-project-custom-field-#{string_custom_field.id}'] > button")
          .click

        expect_checked_state
      end
    end

    string_mapping.reload
    expect(string_mapping.creation_wizard).to be true
  end

  it "persists toggle state after page reload" do
    within_custom_field_section_container(section1) do
      within_custom_field_container(string_custom_field) do
        expect_unchecked_state

        page
          .find("[data-test-selector='toggle-creation-wizard-project-custom-field-#{string_custom_field.id}'] > button")
          .click

        expect_checked_state
      end
    end

    visit project_settings_creation_wizard_path(project, tab: "attributes")

    within_custom_field_section_container(section1) do
      within_custom_field_container(string_custom_field) do
        expect_checked_state
      end
    end

    string_mapping.reload
    expect(string_mapping.creation_wizard).to be true
  end

  it "can toggle a field off" do
    within_custom_field_section_container(section2) do
      within_custom_field_container(list_custom_field) do
        expect_checked_state

        page
          .find("[data-test-selector='toggle-creation-wizard-project-custom-field-#{list_custom_field.id}'] > button")
          .click

        expect_unchecked_state
      end
    end

    list_mapping.reload
    expect(list_mapping.creation_wizard).to be false
  end

  it "cannot toggle a required field off" do
    within_custom_field_section_container(section2) do
      within_custom_field_container(required_int_custom_field) do
        expect_checked_state
        expect_disabled_state
      end
    end

    required_int_mapping.reload
    expect(required_int_mapping.creation_wizard).to be true
  end

  context "with a user custom field" do
    let!(:user_custom_field) do
      create(:user_project_custom_field,
             name: "User field",
             project_custom_field_section: section2)
    end

    let!(:user_custom_field_mapping) do
      create(:project_custom_field_project_mapping,
             project:,
             project_custom_field: user_custom_field,
             # Note that this field is disabled in the creation wizard
             creation_wizard: false)
    end

    before do
      visit project_settings_creation_wizard_path(project, tab: "attributes")
    end

    it "can be toggled" do
      within_custom_field_section_container(section2) do
        within_custom_field_container(user_custom_field) do
          expect_unchecked_state
          expect_enabled_state
        end
      end
    end

    context "when it is configured as PIR assignee" do
      before do
        project.project_creation_wizard_assignee_custom_field_id = user_custom_field.id
        project.save!

        visit project_settings_creation_wizard_path(project, tab: "attributes")
      end

      it "is enabled and cannot be toggled off" do
        within_custom_field_section_container(section2) do
          within_custom_field_container(user_custom_field) do
            expect_checked_state
            expect_disabled_state
          end
        end
      end

      it "is excluded from 'disable all' action" do
        within_custom_field_section_container(section2) do
          within_custom_field_container(user_custom_field) do
            expect_checked_state
          end

          click_link "Disable all"

          within_custom_field_container(user_custom_field) do
            expect_checked_state
          end
        end

        user_custom_field_mapping.reload
        expect(user_custom_field_mapping.creation_wizard).to be true
      end
    end
  end

  it "defaults to false for newly mapped fields, even though the wizard is enabled" do
    new_field = create(:string_project_custom_field,
                       name: "New Field",
                       project_custom_field_section: section1)
    new_mapping = create(:project_custom_field_project_mapping,
                         project:,
                         project_custom_field: new_field)

    visit project_settings_creation_wizard_path(project, tab: "attributes")

    within_custom_field_section_container(section1) do
      within_custom_field_container(new_field) do
        expect_unchecked_state
      end
    end

    new_mapping.reload
    expect(new_mapping.creation_wizard).to be false
  end

  it "can enable all fields in a section at once" do
    within_custom_field_section_container(section1) do
      within_custom_field_container(string_custom_field) do
        expect_unchecked_state
      end

      click_link "Enable all"

      within_custom_field_container(string_custom_field) do
        expect_checked_state
      end
    end

    string_mapping.reload
    expect(string_mapping.creation_wizard).to be true
  end

  it "can disable all fields in a section at once" do
    within_custom_field_section_container(section2) do
      within_custom_field_container(list_custom_field) do
        expect_checked_state
      end

      click_link "Disable all"

      within_custom_field_container(list_custom_field) do
        expect_unchecked_state
      end
    end

    list_mapping.reload
    expect(list_mapping.creation_wizard).to be false
  end

  it "excludes required fields from 'disable all' action" do
    within_custom_field_section_container(section2) do
      within_custom_field_container(required_int_custom_field) do
        expect_checked_state
      end

      click_link "Disable all"

      within_custom_field_container(required_int_custom_field) do
        expect_checked_state
      end
    end

    required_int_mapping.reload
    expect(required_int_mapping.creation_wizard).to be true
  end

  context "when a field is not mapped to the project" do
    let!(:unmapped_field) do
      create(:string_project_custom_field,
             name: "Unmapped Field",
             project_custom_field_section: section1)
    end

    it "does not show the unmapped field" do
      within_custom_field_section_container(section1) do
        expect(page).to have_no_text("Unmapped Field")
      end
    end
  end

  context "when all fields in a section are not mapped to the project" do
    let!(:section3) { create(:project_custom_field_section, name: "Empty Section") }
    let!(:unmapped_field) do
      create(:string_project_custom_field,
             name: "Unmapped Field",
             project_custom_field_section: section3)
    end

    it "does not show the section" do
      expect(page).to have_no_text("Empty Section")
    end
  end

  def within_custom_field_section_container(section, &)
    within("[data-test-selector='project-custom-field-section-#{section.id}']", &)
  end

  def within_custom_field_container(custom_field, &)
    within("[data-test-selector='project-custom-field-#{custom_field.id}']", &)
  end

  def expect_checked_state
    expect(page).to have_css(".ToggleSwitch-track[aria-pressed='true']", wait: 10)
  end

  def expect_unchecked_state
    expect(page).to have_css(".ToggleSwitch-track[aria-pressed='false']", wait: 10)
  end

  def expect_disabled_state
    expect(page).to have_css(".ToggleSwitch-track[disabled='disabled']")
  end

  def expect_enabled_state
    expect(page).to have_no_css(".ToggleSwitch-track[disabled='disabled']")
  end

  def toggle_switch(custom_field)
    find("[data-test-selector='toggle-creation-wizard-project-custom-field-#{custom_field.id}'] > button", wait: 10)
  end
end

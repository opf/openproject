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

RSpec.describe "Projects custom fields mapping via project settings", :js, :with_cuprite do
  let(:project) { create(:project, name: "Foo project", identifier: "foo-project") }
  let(:other_project) { create(:project, name: "Bar project", identifier: "bar-project") }

  let!(:user_with_sufficient_permissions) do
    create(:user,
           firstname: "Project",
           lastname: "Admin",
           member_with_permissions: {
             project => %w[
               view_work_packages
               edit_project
               select_project_custom_fields
             ],
             other_project => %w[
               view_work_packages
               edit_project
               select_project_custom_fields
             ]
           })
  end

  let!(:member_in_project) do
    create(:user,
           firstname: "Member 1",
           lastname: "In Project",
           member_with_permissions: { project => %w[
             edit_project
             view_work_packages
           ] })
  end

  let!(:another_member_in_project) do
    create(:user,
           firstname: "Member 2",
           lastname: "In Project",
           member_with_permissions: { project => %w[
             view_work_packages
           ] })
  end

  let!(:section_for_input_fields) { create(:project_custom_field_section, name: "Input fields") }
  let!(:section_for_select_fields) { create(:project_custom_field_section, name: "Select fields") }
  let!(:section_for_multi_select_fields) { create(:project_custom_field_section, name: "Multi select fields") }

  let!(:boolean_project_custom_field) do
    create(:boolean_project_custom_field, name: "Boolean field",
                                          project_custom_field_section: section_for_input_fields)
  end

  let!(:string_project_custom_field) do
    create(:string_project_custom_field, name: "String field",
                                         project_custom_field_section: section_for_input_fields)
  end

  let!(:list_project_custom_field) do
    create(:list_project_custom_field, name: "List field",
                                       project_custom_field_section: section_for_select_fields,
                                       possible_values: ["Option 1", "Option 2", "Option 3"])
  end

  let!(:multi_list_project_custom_field) do
    create(:list_project_custom_field, name: "Multi list field",
                                       project_custom_field_section: section_for_multi_select_fields,
                                       possible_values: ["Option 1", "Option 2", "Option 3"],
                                       multi_value: true)
  end

  describe "with insufficient permissions" do
    before do
      login_as member_in_project # can edit project but is not allowed to select project custom fields
    end

    it "does not show the menu entry in the project settings menu" do
      visit project_settings_general_path(project)

      within "#menu-sidebar" do
        expect(page).to have_no_css("li[data-name='settings_project_custom_fields']")
      end
    end

    it "does not show the project custom fields page" do
      visit project_settings_project_custom_fields_path(project)

      expect(page).to have_content("You are not authorized to access this page.")
    end
  end

  describe "with sufficient permissions" do
    before do
      login_as user_with_sufficient_permissions
    end

    it "does show the menu entry in the project settings menu" do
      visit project_settings_general_path(project)

      within "#menu-sidebar" do
        expect(page).to have_css("li[data-name='settings_project_custom_fields']")
      end
    end

    it "shows all available project custom fields with their correct mapping state" do
      visit project_settings_project_custom_fields_path(project)

      within_custom_field_section_container(section_for_input_fields) do
        within_custom_field_container(boolean_project_custom_field) do
          expect(page).to have_content("Boolean field")
          expect_type("Bool")
          expect_unchecked_state
        end
        within_custom_field_container(string_project_custom_field) do
          expect(page).to have_content("String field")
          expect_type("String")
          expect_unchecked_state
        end
      end

      within_custom_field_section_container(section_for_select_fields) do
        within_custom_field_container(list_project_custom_field) do
          expect(page).to have_content("List field")
          expect_type("List")
          expect_unchecked_state
        end
      end

      within_custom_field_section_container(section_for_multi_select_fields) do
        within_custom_field_container(multi_list_project_custom_field) do
          expect(page).to have_content("Multi list field")
          expect_type("List")
          expect_unchecked_state
        end
      end
    end

    it "toggles the mapping state of a project custom field for a specific project when clicked" do
      visit project_settings_project_custom_fields_path(project)

      within_custom_field_section_container(section_for_input_fields) do
        within_custom_field_container(boolean_project_custom_field) do
          expect_unchecked_state

          page
            .find("[data-test-selector='toggle-project-custom-field-mapping-#{boolean_project_custom_field.id}'] > button")
            .click

          expect_checked_state # without reloading the page
        end
      end

      # propely persisted and visible after full page reload
      visit project_settings_project_custom_fields_path(project)

      within_custom_field_container(boolean_project_custom_field) do
        expect_checked_state
      end

      # only for this project
      visit project_settings_project_custom_fields_path(other_project)

      within_custom_field_container(boolean_project_custom_field) do
        expect_unchecked_state
      end
    end

    it "enables all mapping states of a section for a specific project when bulk action button clicked" do
      visit project_settings_project_custom_fields_path(project)

      within_custom_field_section_container(section_for_input_fields) do
        page.find("[data-test-selector='enable-all-project-custom-field-mappings-#{section_for_input_fields.id}']").click

        within_custom_field_container(boolean_project_custom_field) do
          expect_checked_state
        end
        within_custom_field_container(string_project_custom_field) do
          expect_checked_state
        end
      end

      within_custom_field_section_container(section_for_select_fields) do
        within_custom_field_container(list_project_custom_field) do
          expect_unchecked_state
        end
      end

      within_custom_field_section_container(section_for_multi_select_fields) do
        within_custom_field_container(multi_list_project_custom_field) do
          expect_unchecked_state
        end
      end
    end

    it "disables all mapping states of a section for a specific project when bulk action button clicked" do
      visit project_settings_project_custom_fields_path(project)

      within_custom_field_section_container(section_for_input_fields) do
        page.find("[data-test-selector='enable-all-project-custom-field-mappings-#{section_for_input_fields.id}']").click

        within_custom_field_container(boolean_project_custom_field) do
          expect_checked_state
        end
        within_custom_field_container(string_project_custom_field) do
          expect_checked_state
        end
      end

      within_custom_field_section_container(section_for_select_fields) do
        within_custom_field_container(list_project_custom_field) do
          expect_unchecked_state
        end
      end

      within_custom_field_section_container(section_for_multi_select_fields) do
        within_custom_field_container(multi_list_project_custom_field) do
          expect_unchecked_state
        end
      end

      within_custom_field_section_container(section_for_input_fields) do
        page.find("[data-test-selector='disable-all-project-custom-field-mappings-#{section_for_input_fields.id}']").click

        within_custom_field_container(boolean_project_custom_field) do
          expect_unchecked_state
        end
        within_custom_field_container(string_project_custom_field) do
          expect_unchecked_state
        end
      end
    end

    it "filters the project custom fields by name with given user input" do
      visit project_settings_project_custom_fields_path(project)

      fill_in "project-custom-fields-mapping-filter", with: "Boolean"

      within_custom_field_section_container(section_for_input_fields) do
        expect(page).to have_content("Boolean field")
        expect(page).to have_no_content("String field")
      end

      within_custom_field_section_container(section_for_select_fields) do
        expect(page).to have_no_content("List field")
      end

      within_custom_field_section_container(section_for_multi_select_fields) do
        expect(page).to have_no_content("Multi list field")
      end
    end

    it "shows the project custom field sections in the correct order" do
      visit project_settings_project_custom_fields_path(project)

      sections = page.all(".op-project-custom-field-section")

      expect(sections.size).to eq(3)

      expect(sections[0].text).to include("Input fields")
      expect(sections[1].text).to include("Select fields")
      expect(sections[2].text).to include("Multi select fields")

      section_for_input_fields.move_to_bottom

      visit project_settings_project_custom_fields_path(project)

      sections = page.all(".op-project-custom-field-section")

      expect(sections.size).to eq(3)

      expect(sections[0].text).to include("Select fields")
      expect(sections[1].text).to include("Multi select fields")
      expect(sections[2].text).to include("Input fields")
    end

    it "shows the project custom fields in the correct order within the sections" do
      visit project_settings_project_custom_fields_path(project)

      within_custom_field_section_container(section_for_input_fields) do
        custom_fields = page.all(".op-project-custom-field")

        expect(custom_fields.size).to eq(2)

        expect(custom_fields[0].text).to include("Boolean field")
        expect(custom_fields[1].text).to include("String field")
      end

      boolean_project_custom_field.move_to_bottom

      visit project_settings_project_custom_fields_path(project)

      within_custom_field_section_container(section_for_input_fields) do
        custom_fields = page.all(".op-project-custom-field")

        expect(custom_fields.size).to eq(2)

        expect(custom_fields[0].text).to include("String field")
        expect(custom_fields[1].text).to include("Boolean field")
      end
    end

    context "with visibility of project custom fields" do
      let!(:section_with_invisible_fields) { create(:project_custom_field_section, name: "Section with invisible fields") }

      let!(:visible_project_custom_field) do
        create(:project_custom_field,
               name: "Normal field",
               admin_only: false,
               projects: [project],
               project_custom_field_section: section_with_invisible_fields)
      end

      let!(:invisible_project_custom_field) do
        create(:project_custom_field,
               name: "Admin only field",
               admin_only: true,
               projects: [project],
               project_custom_field_section: section_with_invisible_fields)
      end

      context "with admin permissions" do
        let!(:admin) do
          create(:admin)
        end

        before do
          login_as admin
          visit project_settings_project_custom_fields_path(project)
        end

        it "shows the invisible project custom fields" do
          within_custom_field_section_container(section_with_invisible_fields) do
            expect(page).to have_content("Normal field")
            expect(page).to have_content("Admin only field")
          end
        end

        it "includeds the invisible project custom fields in the bulk actions" do
          within_custom_field_section_container(section_with_invisible_fields) do
            page
              .find("[data-test-selector='disable-all-project-custom-field-mappings-#{section_with_invisible_fields.id}']")
              .click

            within_custom_field_container(visible_project_custom_field) do
              expect_unchecked_state
            end
            within_custom_field_container(invisible_project_custom_field) do
              expect_unchecked_state
            end

            page
              .find("[data-test-selector='enable-all-project-custom-field-mappings-#{section_with_invisible_fields.id}']")
              .click

            within_custom_field_container(visible_project_custom_field) do
              expect_checked_state
            end
            within_custom_field_container(invisible_project_custom_field) do
              expect_checked_state
            end
          end
        end
      end

      context "with non-admin permissions" do
        before do
          login_as user_with_sufficient_permissions
          visit project_settings_project_custom_fields_path(project)
        end

        it "does not show the invisible project custom fields" do
          within_custom_field_section_container(section_with_invisible_fields) do
            expect(page).to have_content("Normal field")
            expect(page).to have_no_content("Admin only field")
          end
        end

        it "does not include the invisible project custom fields in the bulk actions" do
          within_custom_field_section_container(section_with_invisible_fields) do
            page
              .find("[data-test-selector='disable-all-project-custom-field-mappings-#{section_with_invisible_fields.id}']")
              .click

            within_custom_field_container(visible_project_custom_field) do
              expect_unchecked_state
            end

            # the invisible field is not affected by the bulk action
            expect(project.project_custom_fields).to include(invisible_project_custom_field)

            # disable manually
            project.project_custom_field_project_mappings.find_by(custom_field_id: invisible_project_custom_field.id).destroy!

            page.find("[data-test-selector='enable-all-project-custom-field-mappings-#{section_with_invisible_fields.id}']").click

            within_custom_field_container(visible_project_custom_field) do
              expect_checked_state
            end

            # the invisible field is not affected by the bulk action
            expect(project.project_custom_fields).not_to include(invisible_project_custom_field)
          end
        end
      end
    end
  end

  def expect_type(type)
    within "[data-test-selector='custom-field-type']" do
      expect(page).to have_content(type)
    end
  end

  def expect_checked_state
    expect(page).to have_css(".ToggleSwitch-statusOn")
  end

  def expect_unchecked_state
    expect(page).to have_css(".ToggleSwitch-statusOff")
  end

  def within_custom_field_section_container(section, &)
    within("[data-test-selector='project-custom-field-section-#{section.id}']", &)
  end

  def within_custom_field_container(custom_field, &)
    within("[data-test-selector='project-custom-field-#{custom_field.id}']", &)
  end
end

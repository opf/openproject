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
require_relative "shared_context"

RSpec.describe "List project custom fields", :js do
  include_context "with seeded project custom fields"

  context "with unsufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit admin_settings_project_custom_fields_path

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      visit admin_settings_project_custom_fields_path
    end

    it "shows all sections in the correct order and allows reordering via menu or drag and drop" do
      containers = page.all(".op-project-custom-field-section-container")

      expect(containers[0].text).to include(section_for_input_fields.name)
      expect(containers[1].text).to include(section_for_select_fields.name)
      expect(containers[2].text).to include(section_for_multi_select_fields.name)

      perform_action_for_project_custom_field_section(section_for_multi_select_fields, "Move up")

      visit admin_settings_project_custom_fields_path

      containers = page.all(".op-project-custom-field-section-container")

      expect(containers[0].text).to include(section_for_input_fields.name)
      expect(containers[1].text).to include(section_for_multi_select_fields.name)
      expect(containers[2].text).to include(section_for_select_fields.name)

      # TODO: Add drag and drop test
    end

    it "allows to delete a section only if no project custom fields are assigned to it" do
      within_project_custom_field_section_menu(section_for_multi_select_fields) do
        expect(page).to have_css("button[aria-disabled='true']", text: "Delete")
      end

      multi_list_project_custom_field.destroy
      multi_user_project_custom_field.destroy
      multi_version_project_custom_field.destroy

      visit admin_settings_project_custom_fields_path

      within_project_custom_field_section_menu(section_for_multi_select_fields) do
        expect(page).to have_no_css("button[aria-disabled='true']", text: "Delete")
        expect(page).to have_button("Delete")

        accept_confirm do
          click_on("Delete")
        end
      end

      expect(page)
        .to have_no_css("[data-test-selector='project-custom-field-section-container-#{section_for_multi_select_fields.id}']")
    end

    it "allows to edit a section" do
      within_project_custom_field_section_menu(section_for_input_fields) do
        click_on("Edit title")
      end

      fill_in("project_custom_field_section_name", with: "Updated section name")

      click_on("Save")

      expect(page).to have_no_text(section_for_input_fields.name)
      expect(page).to have_text("Updated section name")
    end

    it "allows to create a new section" do
      within "#settings-project-custom-fields-header-component" do
        click_on("dialog-show-project-custom-field-section-dialog")
      end

      fill_in("project_custom_field_section_name", with: "New section name")

      click_on("Save")

      expect(page).to have_text("New section name")

      containers = page.all(".op-project-custom-field-section-container")

      expect(containers[0].text).to include("New section name")
      expect(containers[1].text).to include(section_for_input_fields.name)
      expect(containers[2].text).to include(section_for_select_fields.name)
      expect(containers[3].text).to include(section_for_multi_select_fields.name)
    end

    describe "managing project custom fields" do
      it "shows all custom fields in the correct order within their section and allows reordering via menu or drag and drop" do
        within_project_custom_field_section_container(section_for_input_fields) do
          containers = page.all(".op-project-custom-field-container")

          expect(containers[0].text).to include(boolean_project_custom_field.name)
          expect(containers[1].text).to include(string_project_custom_field.name)
          expect(containers[2].text).to include(integer_project_custom_field.name)
          expect(containers[3].text).to include(float_project_custom_field.name)
          expect(containers[4].text).to include(date_project_custom_field.name)
          expect(containers[5].text).to include(text_project_custom_field.name)
        end

        within_project_custom_field_section_container(section_for_select_fields) do
          containers = page.all(".op-project-custom-field-container")

          expect(containers[0].text).to include(list_project_custom_field.name)
          expect(containers[1].text).to include(version_project_custom_field.name)
          expect(containers[2].text).to include(user_project_custom_field.name)
        end

        within_project_custom_field_section_container(section_for_multi_select_fields) do
          containers = page.all(".op-project-custom-field-container")

          expect(containers[0].text).to include(multi_list_project_custom_field.name)
          expect(containers[1].text).to include(multi_version_project_custom_field.name)
          expect(containers[2].text).to include(multi_user_project_custom_field.name)
        end

        perform_action_for_project_custom_field(multi_user_project_custom_field, "Move up")

        visit admin_settings_project_custom_fields_path

        within_project_custom_field_section_container(section_for_multi_select_fields) do
          containers = page.all(".op-project-custom-field-container")

          expect(containers[0].text).to include(multi_list_project_custom_field.name)
          expect(containers[1].text).to include(multi_user_project_custom_field.name)
          expect(containers[2].text).to include(multi_version_project_custom_field.name)
        end

        # TODO: Add drag and drop test
      end

      it "shows the number of projects using a custom field" do
        within_project_custom_field_container(boolean_project_custom_field) do
          expect(page).to have_text("0 Projects")
        end

        project = create(:project)
        project.project_custom_fields << boolean_project_custom_field

        visit admin_settings_project_custom_fields_path

        within_project_custom_field_container(boolean_project_custom_field) do
          expect(page).to have_text("1 Project")
        end
      end

      it "allows to delete a custom field" do
        within_project_custom_field_menu(boolean_project_custom_field) do
          accept_confirm do
            click_on("Delete")
          end
        end

        expect(page).to have_no_css("[data-test-selector='project-custom-field-container-#{boolean_project_custom_field.id}']")
      end

      it "redirects to the custom field edit page via menu item" do
        within_project_custom_field_menu(boolean_project_custom_field) do
          click_on("Edit")
        end

        expect(page).to have_current_path(edit_admin_settings_project_custom_field_path(boolean_project_custom_field))
      end

      it "redirects to the custom field edit page via click on the name of the custom field" do
        within_project_custom_field_container(boolean_project_custom_field) do
          click_on(boolean_project_custom_field.name)
        end

        expect(page).to have_current_path(edit_admin_settings_project_custom_field_path(boolean_project_custom_field))
      end

      it "redirects to the custom field new page via header menu button" do
        page.find("[data-test-selector='new-project-custom-field-button']").click

        expect(page).to have_current_path(new_admin_settings_project_custom_field_path(type: "ProjectCustomField"))
      end

      it "redirects to the custom field new page via button in empty sections" do
        within_project_custom_field_section_container(section_for_multi_select_fields) do
          expect(page).to have_no_css("[data-test-selector='new-project-custom-field-button']")
        end

        multi_list_project_custom_field.destroy
        multi_user_project_custom_field.destroy
        multi_version_project_custom_field.destroy

        visit admin_settings_project_custom_fields_path

        within_project_custom_field_section_container(section_for_multi_select_fields) do
          page.find("[data-test-selector='new-project-custom-field-button']").click
        end

        expect(page).to have_current_path(new_admin_settings_project_custom_field_path(
                                            type: "ProjectCustomField",
                                            custom_field_section_id: section_for_multi_select_fields.id
                                          ))
      end
    end
  end

  # helper methods:

  def within_project_custom_field_section_container(section, &block)
    within("[data-test-selector='project-custom-field-section-container-#{section.id}']", &block)
  end

  def within_project_custom_field_section_menu(section, &block)
    within_project_custom_field_section_container(section) do
      page.find("[data-test-selector='project-custom-field-section-action-menu']").click
      within("anchored-position", &block)
    end
  end

  def perform_action_for_project_custom_field_section(section, action)
    within_project_custom_field_section_menu(section) do
      click_on(action)
    end
    sleep 0.5 # quick fix: allow the brower to process the action
  end

  def within_project_custom_field_container(custom_field, &block)
    within("[data-test-selector='project-custom-field-container-#{custom_field.id}']", &block)
  end

  def within_project_custom_field_menu(section, &block)
    within_project_custom_field_container(section) do
      page.find("[data-test-selector='project-custom-field-action-menu']").click
      within("anchored-position", &block)
    end
  end

  def perform_action_for_project_custom_field(custom_field, action)
    within_project_custom_field_menu(custom_field) do
      click_on(action)
    end
    sleep 0.5 # quick fix: allow the brower to process the action
  end
end

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
require_relative "shared_context"

RSpec.describe "List project custom fields", :js do
  include_context "with seeded project custom fields"

  let(:cf_index_page) { Pages::Admin::Settings::ProjectCustomFields::Index.new }

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      cf_index_page.visit!

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      cf_index_page.visit!
    end

    it "only allows project attribute creation when there is at least one section" do
      # All sections are there, so we can add project attributes
      cf_index_page.expect_add_project_attribute_submenu

      section_for_input_fields.destroy
      section_for_multi_select_fields.destroy
      select_fields.each(&:destroy)

      cf_index_page.visit!

      # The (empty) select section is still there, so we can still add project attributes
      cf_index_page.expect_add_project_attribute_submenu

      within_project_custom_field_section_menu(section_for_select_fields) do
        accept_confirm do
          click_on("Delete")
        end
      end

      # Now there are no sections left, so we cannot add project attributes:
      # Turbo stream updated the component properly:
      cf_index_page.expect_no_add_project_attribute_submenu(close: false)

      # Revisiting the page again should not change anything:
      cf_index_page.visit!
      cf_index_page.expect_no_add_project_attribute_submenu(close: false)
    end

    it "shows all sections in the correct order and allows reordering via menu or drag and drop" do
      containers = page.all(".op-project-custom-field-section-container")

      expect(containers[0].text).to include(section_for_input_fields.name)
      expect(containers[1].text).to include(section_for_select_fields.name)
      expect(containers[2].text).to include(section_for_multi_select_fields.name)

      perform_action_for_project_custom_field_section(section_for_multi_select_fields, "Move up")

      cf_index_page.visit!

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

      cf_index_page.visit!

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
        page.find_test_selector("project-attributes-add-menu-button").click
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
      context "with calculated value type" do
        it "offers the type for creation with enterprise icon" do
          cf_index_page.expect_having_create_item(I18n.t("label_calculated_value"), enterprise_icon: true)
        end

        context "with enterprise feature calculated_values", with_ee: %i[calculated_values] do
          it "offers the type for creation without enterprise icon" do
            cf_index_page.expect_having_create_item(I18n.t("label_calculated_value"), enterprise_icon: false)
          end
        end

        context "with fields of type calculated value", with_ee: %i[calculated_values] do
          let!(:calculated_value_project_custom_field) do
            create(:calculated_value_project_custom_field,
                   name: "Calculated value field",
                   formula: "42 + 1",
                   project_custom_field_section: section_for_input_fields)
          end

          before do
            login_as(admin)
            cf_index_page.visit!
          end

          it "lists the calculated value custom field" do
            within_project_custom_field_section_container(section_for_input_fields) do
              containers = page.all(".op-project-custom-field-container")

              expect(containers.last.text).to include(calculated_value_project_custom_field.name)
            end
          end
        end
      end

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
          expect(page).to have_text("0 projects")
        end

        project = create(:project)
        project.project_custom_fields << boolean_project_custom_field

        cf_index_page.visit!

        within_project_custom_field_container(boolean_project_custom_field) do
          expect(page).to have_text("1 project")
        end

        for_all_cf = create(:project_custom_field, :integer, is_for_all: true)
        cf_index_page.visit!
        within_project_custom_field_container(for_all_cf) do
          expect(page).to have_text("All projects")
        end
      end

      describe "deleting custom fields" do
        it "allows to delete a custom field" do
          within_project_custom_field_menu(boolean_project_custom_field) do
            accept_confirm do
              click_on("Delete")
            end
          end

          expect(page).to have_no_css("[data-test-selector='project-custom-field-container-#{boolean_project_custom_field.id}']")
        end

        it "prevents deletion of custom field used in a calculated value custom fields" do
          within_project_custom_field_menu(integer_project_custom_field) do
            accept_confirm do
              click_on("Delete")
            end
          end
          page.within(find_flash_element(type: :error)) do
            expect(page).to have_cf_admin_link(calculated_from_int_project_custom_field)
            expect(page).to have_cf_admin_link(calculated_from_int_and_float_project_custom_field)
          end
          expect_and_dismiss_flash(
            message: "Integer field is used in project attribute calculations: Calculated field using int and " \
                     "Calculated field using int and float.",
            type: :error
          )
          expect(page).to have_css("[data-test-selector='project-custom-field-container-#{integer_project_custom_field.id}']")

          within_project_custom_field_menu(float_project_custom_field) do
            accept_confirm do
              click_on("Delete")
            end
          end
          page.within(find_flash_element(type: :error)) do
            expect(page).to have_cf_admin_link(calculated_from_int_and_float_project_custom_field)
          end
          expect_and_dismiss_flash(
            message: "Float field is used in project attribute calculation Calculated field using int and float.",
            type: :error
          )
          expect(page).to have_css("[data-test-selector='project-custom-field-container-#{float_project_custom_field.id}']")

          # Can delete calculated value field
          within_project_custom_field_menu(calculated_from_int_and_float_project_custom_field) do
            accept_confirm do
              click_on("Delete")
            end
          end
          expect(page).to have_no_css(
            "[data-test-selector='project-custom-field-container-#{calculated_from_int_and_float_project_custom_field.id}']"
          )

          # Can delete used custom field afterwards
          within_project_custom_field_menu(float_project_custom_field) do
            accept_confirm do
              click_on("Delete")
            end
          end
          expect(page).to have_no_css("[data-test-selector='project-custom-field-container-#{float_project_custom_field.id}']")
        end

        def have_cf_admin_link(custom_field)
          have_link(custom_field.name, href: admin_settings_project_custom_field_path(custom_field))
        end
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

      it "redirects to the custom field new page via button in empty sections" do
        within_project_custom_field_section_container(section_for_multi_select_fields) do
          expect(page).not_to have_test_selector("new-project-custom-field-in-section-button")
        end

        multi_list_project_custom_field.destroy
        multi_user_project_custom_field.destroy
        multi_version_project_custom_field.destroy

        cf_index_page.visit!

        within_project_custom_field_section_container(section_for_multi_select_fields) do
          page.find_test_selector("new-project-custom-field-in-section-button").click
          page.find_test_selector("new-project-custom-field-in-section-button-int").click
        end

        expect(page).to have_current_path(new_admin_settings_project_custom_field_path(
                                            field_format: "int",
                                            custom_field_section_id: section_for_multi_select_fields.id
                                          ))
      end
    end
  end

  # helper methods:

  def within_project_custom_field_section_container(section, &)
    within_test_selector("project-custom-field-section-container-#{section.id}", &)
  end

  def within_project_custom_field_section_menu(section, &)
    within_project_custom_field_section_container(section) do
      page.find_test_selector("project-custom-field-section-action-menu").click
      within("anchored-position", &)
    end
  end

  def perform_action_for_project_custom_field_section(section, action)
    within_project_custom_field_section_menu(section) do
      click_on(action)
    end
    sleep 0.5 # quick fix: allow the browser to process the action
  end

  def within_project_custom_field_container(custom_field, &)
    within_test_selector("project-custom-field-container-#{custom_field.id}", &)
  end

  def within_project_custom_field_menu(section, &)
    within_project_custom_field_container(section) do
      page.find_test_selector("project-custom-field-action-menu").click
      within("anchored-position", &)
    end
  end

  def perform_action_for_project_custom_field(custom_field, action)
    within_project_custom_field_menu(custom_field) do
      click_on(action)
    end
    sleep 0.5 # quick fix: allow the browser to process the action
  end
end

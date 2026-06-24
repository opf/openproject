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

RSpec.describe "List user custom fields", :js do
  include_context "with seeded user custom fields"

  let(:cf_index_page) { Pages::Admin::Settings::UserCustomFields::Index.new }

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

    it "only allows user attribute creation when there is at least one section" do
      cf_index_page.expect_add_user_attribute_submenu

      boolean_user_custom_field.destroy
      string_user_custom_field.destroy
      list_user_custom_field.destroy
      section_for_input_fields.destroy

      cf_index_page.visit!

      # The (empty) select section is still there, so we can still add user attributes
      cf_index_page.expect_add_user_attribute_submenu

      within_user_custom_field_section_menu(section_for_select_fields) do
        accept_confirm do
          click_on("Delete")
        end
      end

      # Now there are no sections left
      cf_index_page.expect_no_add_user_attribute_submenu(close: false)

      cf_index_page.visit!
      cf_index_page.expect_no_add_user_attribute_submenu(close: false)
    end

    it "shows all sections in the correct order" do
      containers = page.all(".op-user-custom-field-section-container")

      expect(containers[0].text).to include(section_for_input_fields.name)
      expect(containers[1].text).to include(section_for_select_fields.name)
    end

    it "shows all custom fields within their section" do
      within_user_custom_field_section_container(section_for_input_fields) do
        containers = page.all(".op-user-custom-field-container")

        expect(containers[0].text).to include(boolean_user_custom_field.name)
        expect(containers[1].text).to include(string_user_custom_field.name)
      end

      within_user_custom_field_section_container(section_for_select_fields) do
        expect(page).to have_text(list_user_custom_field.name)
      end
    end

    it "allows to delete a section only if no user custom fields are assigned to it" do
      within_user_custom_field_section_menu(section_for_select_fields) do
        expect(page).to have_css("button[aria-disabled='true']", text: "Delete")
      end

      list_user_custom_field.destroy

      cf_index_page.visit!

      within_user_custom_field_section_menu(section_for_select_fields) do
        expect(page).to have_no_css("button[aria-disabled='true']", text: "Delete")

        accept_confirm do
          click_on("Delete")
        end
      end

      expect(page)
        .to have_no_css("[data-test-selector='user-custom-field-section-container-#{section_for_select_fields.id}']")
    end

    it "allows to edit a section title" do
      within_user_custom_field_section_menu(section_for_input_fields) do
        click_on("Edit title")
      end

      fill_in("user_custom_field_section_name", with: "Updated section name")

      click_on("Save")

      expect(page).to have_no_text(section_for_input_fields.name)
      expect(page).to have_text("Updated section name")
    end

    it "allows to create a new section" do
      within "#settings-user-custom-fields-header-component" do
        page.find_test_selector("user-attributes-add-menu-button").click
        click_on("dialog-show-user-custom-field-section-dialog")
      end

      fill_in("user_custom_field_section_name", with: "New section name")

      click_on("Save")

      expect(page).to have_text("New section name")

      containers = page.all(".op-user-custom-field-section-container")

      expect(containers[0].text).to include("New section name")
      expect(containers[1].text).to include(section_for_input_fields.name)
      expect(containers[2].text).to include(section_for_select_fields.name)
    end

    it "allows to delete a custom field" do
      within_user_custom_field_menu(boolean_user_custom_field) do
        accept_confirm do
          click_on("Delete")
        end
      end

      expect(page).to have_no_css("[data-test-selector='user-custom-field-container-#{boolean_user_custom_field.id}']")
    end

    it "redirects to the custom field edit page via menu item" do
      within_user_custom_field_menu(boolean_user_custom_field) do
        click_on("Edit")
      end

      expect(page).to have_current_path(edit_admin_settings_user_custom_field_path(boolean_user_custom_field))
    end

    it "redirects to the custom field edit page via click on the name" do
      within_user_custom_field_container(boolean_user_custom_field) do
        click_on(boolean_user_custom_field.name)
      end

      expect(page).to have_current_path(edit_admin_settings_user_custom_field_path(boolean_user_custom_field))
    end

    it "redirects to the new custom field page via the empty section button" do
      boolean_user_custom_field.destroy
      string_user_custom_field.destroy

      cf_index_page.visit!

      within_user_custom_field_section_container(section_for_input_fields) do
        page.find_test_selector("new-user-custom-field-in-section-button").click
        page.find_test_selector("new-user-custom-field-in-section-button-int").click
      end

      expect(page).to have_current_path(new_admin_settings_user_custom_field_path(
                                          field_format: "int",
                                          custom_field_section_id: section_for_input_fields.id
                                        ))
    end

    it "allows adding an attribute to a non-empty section via the section actions menu" do
      # section_for_input_fields already has custom fields (non-empty),
      # so the empty-state button is not shown here — the submenu must be.
      within_user_custom_field_section_menu(section_for_input_fields) do
        page.find_test_selector("new-user-custom-field-in-section-submenu").click
        page.find_test_selector("new-user-custom-field-in-section-button-int").click
      end

      expect(page).to have_current_path(new_admin_settings_user_custom_field_path(
                                          field_format: "int",
                                          custom_field_section_id: section_for_input_fields.id
                                        ))
    end
  end

  # helper methods

  def within_user_custom_field_section_container(section, &)
    within_test_selector("user-custom-field-section-container-#{section.id}", &)
  end

  def within_user_custom_field_section_menu(section, &)
    within_user_custom_field_section_container(section) do
      page.find_test_selector("user-custom-field-section-action-menu").click
      within("anchored-position", &)
    end
  end

  def within_user_custom_field_container(custom_field, &)
    within_test_selector("user-custom-field-container-#{custom_field.id}", &)
  end

  def within_user_custom_field_menu(custom_field, &)
    within_user_custom_field_container(custom_field) do
      page.find_test_selector("user-custom-field-action-menu").click
      within("anchored-position", &)
    end
  end
end

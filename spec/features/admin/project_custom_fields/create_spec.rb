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

RSpec.describe "Create project custom fields", :js do
  include_context "with seeded project custom fields"

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit new_admin_settings_project_custom_field_path

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      visit new_admin_settings_project_custom_field_path
    end

    it "shows a correct breadcrumb menu" do
      within ".PageHeader-breadcrumbs" do
        expect(page).to have_link("Administration")
        expect(page).to have_link("Projects")
        expect(page).to have_link("Project attributes")
        expect(page).to have_text("New attribute")
      end
    end

    it "allows to create a new project custom field with an associated section" do
      # TODO: reuse specs for classic custom field form in order to test for other attribute settings
      expect(page).to have_css(".PageHeader-title", text: "New attribute")

      fill_in("custom_field_name", with: "New custom field")
      select(section_for_select_fields.name, from: "custom_field_custom_field_section_id")
      check "Admin-only"

      click_on("Save")

      # redirects to the overview page
      # the tab parameter is set as the redirect originates from the former custom field controller but does not have an effect
      expect(page).to have_current_path(admin_settings_project_custom_fields_path(tab: "ProjectCustomField"))

      expect(page).to have_text("New custom field")

      latest_custom_field = ProjectCustomField.reorder(created_at: :asc).last

      expect(latest_custom_field.name).to eq("New custom field")
      expect(latest_custom_field.admin_only).to be(true)
      expect(latest_custom_field.project_custom_field_section).to eq(section_for_select_fields)
    end

    it "allows to create a new project custom field with a prefilled section via url param" do
      visit new_admin_settings_project_custom_field_path(custom_field_section_id: section_for_multi_select_fields.id)

      fill_in("custom_field_name", with: "New custom field")

      click_on("Save")

      # redirects to the overview page
      # the tab parameter is set as the redirect originates from the former custom field controller but does not have an effect
      expect(page).to have_current_path(admin_settings_project_custom_fields_path(tab: "ProjectCustomField"))

      latest_custom_field = ProjectCustomField.reorder(created_at: :asc).last

      expect(latest_custom_field.name).to eq("New custom field")
      expect(latest_custom_field.project_custom_field_section).to eq(section_for_multi_select_fields)
    end

    it "prevents creating a new project custom field with an empty name" do
      click_on("Save")

      expect(page).to have_field "custom_field_name", validation_message: "Please fill out this field."

      # expect no redirect
      expect(page).to have_no_current_path(admin_settings_project_custom_fields_path(tab: "ProjectCustomField"))
      expect(page).to have_current_path(new_admin_settings_project_custom_field_path)
    end

    context "without any existing sections" do
      before do
        ProjectCustomFieldSection.destroy_all
        visit new_admin_settings_project_custom_field_path
      end

      it "prevents creating a new project custom field with an empty name" do
        fill_in("custom_field_name", with: "New custom field")

        click_on("Save")

        expect(page).to have_field "custom_field_custom_field_section_id",
                                   validation_message: "Please select an item in the list."
      end
    end
  end
end

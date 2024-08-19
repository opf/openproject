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

RSpec.describe "Edit project custom fields", :js do
  include_context "with seeded project custom fields"

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit edit_admin_settings_project_custom_field_path(boolean_project_custom_field)

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
      visit edit_admin_settings_project_custom_field_path(boolean_project_custom_field)
    end

    it "shows a correct breadcrumb menu" do
      within ".PageHeader-breadcrumbs" do
        expect(page).to have_link("Administration")
        expect(page).to have_link("Projects")
        expect(page).to have_link("Project attributes")
        expect(page).to have_text(boolean_project_custom_field.name)
      end
    end

    it "shows tab navigation" do
      within_test_selector("project_attribute_detail_header") do
        expect(page).to have_link("Details")
        expect(page).to have_link("Enabled in projects")
      end
    end

    it "allows to change basic attributes and the section of the project custom field" do
      # TODO: reuse specs for classic custom field form in order to test for other attribute manipulations
      expect(page).to have_css(".PageHeader-title", text: boolean_project_custom_field.name)

      fill_in("custom_field_name", with: "Updated name", fill_options: { clear: :backspace })
      select(section_for_select_fields.name, from: "custom_field_custom_field_section_id")

      click_on("Save")

      expect(page).to have_text("Successful update")

      expect(page).to have_css(".PageHeader-title", text: "Updated name")

      expect(boolean_project_custom_field.reload.name).to eq("Updated name")
      expect(boolean_project_custom_field.reload.project_custom_field_section).to eq(section_for_select_fields)

      within ".PageHeader-breadcrumbs" do
        expect(page).to have_link("Administration")
        expect(page).to have_link("Projects")
        expect(page).to have_link("Project attributes")
        expect(page).to have_text("Updated name")
      end
    end

    it "prevents saving a project custom field with an empty name" do
      original_name = boolean_project_custom_field.name

      fill_in("custom_field_name", with: "")
      click_on("Save")

      expect(page).to have_field "custom_field_name", validation_message: "Please fill out this field."

      expect(page).to have_no_text("Successful update")

      expect(page).to have_css(".PageHeader-title", text: original_name)
      expect(boolean_project_custom_field.reload.name).to eq(original_name)
    end
  end
end

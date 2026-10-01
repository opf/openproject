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

RSpec.describe "Create user custom fields in sections", :js do
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

    context "when creating a Text user attribute" do
      before do
        cf_index_page.click_to_create_new_custom_field("Text")
      end

      it "shows the correct breadcrumb" do
        within ".PageHeader-breadcrumbs" do
          expect(page).to have_link("Administration")
          expect(page).to have_link("Users and permissions")
          expect(page).to have_link("User attributes")
          expect(page).to have_text("Text: New attribute")
        end
      end

      it "creates a user attribute assigned to a section" do
        fill_in("custom_field_name", with: "Job title")
        select(section_for_input_fields.name, from: "custom_field_custom_field_section_id")
        check "Admin-only"

        click_on("Save")

        expect(page).to have_text("Successful creation")

        created = UserCustomField.find_by(name: "Job title")
        expect(page).to have_current_path(edit_admin_settings_user_custom_field_path(created))
        expect(created.admin_only).to be(true)
        expect(created.user_custom_field_section).to eq(section_for_input_fields)
      end

      it "allows creating a user attribute with a prefilled section via URL param" do
        visit new_admin_settings_user_custom_field_path(field_format: "text",
                                                        custom_field_section_id: section_for_select_fields.id)

        fill_in("custom_field_name", with: "Biography")
        click_on("Save")

        expect(page).to have_text("Successful creation")

        created = UserCustomField.find_by(name: "Biography")
        expect(created.user_custom_field_section).to eq(section_for_select_fields)
      end

      it "prevents creating a user attribute with an empty name" do
        click_on("Save")

        expect(page).to have_field("custom_field_name", with: "", validation_error: "Name can't be blank")
        expect(page).to have_current_path(new_admin_settings_user_custom_field_path(field_format: "string"))
      end

      context "without any existing sections" do
        before do
          UserCustomField.delete_all
          UserCustomFieldSection.delete_all
          cf_index_page.visit!
        end

        it "prevents creating a new user attribute" do
          cf_index_page.expect_no_add_user_attribute_submenu
        end
      end
    end
  end
end

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

RSpec.describe "User custom field attribute help text", :js do
  include Flash::Expectations

  shared_let(:admin) { create(:admin) }
  shared_let(:section) { create(:user_custom_field_section) }
  shared_let(:user_custom_field) do
    create(:user_custom_field, name: "Job title", field_format: "text", user_custom_field_section: section)
  end

  let(:editor) { Components::WysiwygEditor.new }

  before { login_as(admin) }

  describe "creating attribute help text" do
    it "allows creating help text from the custom field edit page" do
      visit edit_admin_settings_user_custom_field_path(user_custom_field)

      click_on "Help text"

      expect(page).to have_current_path(
        attribute_help_text_admin_settings_user_custom_field_path(user_custom_field)
      )

      expect(page).to have_no_css("#attribute_help_text_attribute_name")

      fill_in "Caption", with: "Job title help"
      editor.set_markdown("Enter your current job title")

      click_button "Save"

      expect(page).to have_current_path(
        attribute_help_text_admin_settings_user_custom_field_path(user_custom_field)
      )
      expect(page).to have_text("Successful update")

      help_text = AttributeHelpText::User.find_by(attribute_name: "custom_field_#{user_custom_field.id}")
      expect(help_text).to be_present
      expect(help_text.caption).to eq("Job title help")
      expect(help_text.help_text).to include("Enter your current job title")
    end
  end

  describe "editing attribute help text" do
    let!(:existing_help_text) do
      create(:user_help_text,
             attribute_name: "custom_field_#{user_custom_field.id}",
             caption: "Original caption",
             help_text: "Original help text")
    end

    it "allows editing existing help text" do
      visit attribute_help_text_admin_settings_user_custom_field_path(user_custom_field)

      expect(page).to have_field("Caption", with: "Original caption")

      fill_in "Caption", with: "Updated caption"
      editor.clear
      editor.set_markdown("Updated help text")

      click_button "Save"

      expect(page).to have_text("Successful update")

      existing_help_text.reload
      expect(existing_help_text.caption).to eq("Updated caption")
      expect(existing_help_text.help_text).to eq("Updated help text")
    end

    it "shows validation errors when clearing help text" do
      visit attribute_help_text_admin_settings_user_custom_field_path(user_custom_field)

      editor.clear
      editor.set_markdown(" ")
      click_button "Save"
      expect(page).to have_text("Help text can't be blank")
    end
  end

  describe "tab navigation" do
    it "navigates between Details and Help text tabs" do
      visit edit_admin_settings_user_custom_field_path(user_custom_field)

      click_on "Help text"
      expect(page).to have_current_path(
        attribute_help_text_admin_settings_user_custom_field_path(user_custom_field)
      )

      click_on "Details"
      expect(page).to have_current_path(
        edit_admin_settings_user_custom_field_path(user_custom_field)
      )
    end
  end
end

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Project custom field attribute help text", :js do
  include Flash::Expectations

  shared_let(:admin) { create(:admin) }
  shared_let(:project_custom_field_section) { create(:project_custom_field_section) }
  shared_let(:project_custom_field) do
    create(:project_custom_field,
           name: "Project Rating",
           field_format: "text",
           project_custom_field_section:)
  end

  let(:editor) { Components::WysiwygEditor.new }
  let(:image_fixture) { UploadedFile.load_from("spec/fixtures/files/image.png") }

  before do
    login_as(admin)
  end

  describe "creating attribute help text for project custom field" do
    it "allows creating help text from the custom field edit page" do
      visit edit_admin_settings_project_custom_field_path(project_custom_field)

      # Navigate to attribute help text tab
      click_on AttributeHelpText.human_attribute_name(:help_text)

      expect(page).to have_current_path(
        attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)
      )

      # Verify attribute field is hidden
      expect(page).to have_no_css("#attribute_help_text_attribute_name")

      # Fill in caption
      fill_in "Caption", with: "Rating help"

      # Fill in help text
      editor.set_markdown("Please rate this project from 1-5 stars")

      # Save
      click_button "Save"

      # Should return to the attribute help text tab
      expect(page).to have_current_path(
        attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)
      )
      expect(page).to have_text("Successful update")

      # Verify the help text was created
      help_text = AttributeHelpText::Project.find_by(attribute_name: "custom_field_#{project_custom_field.id}")
      expect(help_text).to be_present
      expect(help_text.caption).to eq("Rating help")
      expect(help_text.help_text).to include("Please rate this project from 1-5 stars")
    end

    it "allows creating help text with attachments" do
      visit attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)

      # Fill in caption
      fill_in "Caption", with: "Rating with image"

      # Fill in help text
      editor.set_markdown("Rating guidelines below")

      # Add an image
      editor.drag_attachment image_fixture.path, "Rating guideline image"
      editor.attachments_list.expect_attached("image.png")

      # Save
      click_button "Save"

      expect(page).to have_text("Successful update")

      # Verify the help text was created with attachment
      help_text = AttributeHelpText::Project.find_by(attribute_name: "custom_field_#{project_custom_field.id}")
      expect(help_text).to be_present
      expect(help_text.help_text).to include("Rating guidelines below")
      expect(help_text.help_text).to match(/\/api\/v3\/attachments\/\d+\/content/)
      expect(help_text.attachments).to be_present
    end
  end

  describe "editing attribute help text for project custom field" do
    let!(:existing_help_text) do
      create(:project_help_text,
             attribute_name: "custom_field_#{project_custom_field.id}",
             caption: "Original caption",
             help_text: "Original help text")
    end

    it "allows editing existing help text" do
      visit attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)

      # Should show existing values
      expect(page).to have_field("Caption", with: "Original caption")

      # Update caption
      fill_in "Caption", with: "Updated caption"

      # Update help text
      editor.clear
      editor.set_markdown("Updated help text with **bold** text")

      # Save
      click_button "Save"

      expect(page).to have_text("Successful update")

      # Verify the help text was updated
      existing_help_text.reload
      expect(existing_help_text.caption).to eq("Updated caption")
      expect(existing_help_text.help_text).to eq("Updated help text with **bold** text")
    end

    it "shows validation errors when clearing help text" do
      visit attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)

      editor.clear
      editor.set_markdown(" ")
      click_button "Save"
      expect(page).to have_text("Help text can't be blank")
    end

    it "persists caption as optional field" do
      visit attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)

      # Clear caption but keep help text
      fill_in "Caption", with: ""
      editor.clear
      editor.set_markdown("Help text without caption")

      # Save
      click_button "Save"

      expect(page).to have_text("Successful update")

      # Verify caption is nil but help text is saved
      existing_help_text.reload
      expect(existing_help_text.caption).to be_blank
      expect(existing_help_text.help_text).to eq("Help text without caption")
    end
  end

  describe "navigation between tabs" do
    it "maintains tab context when navigating" do
      visit edit_admin_settings_project_custom_field_path(project_custom_field)

      # Navigate to attribute help text tab
      click_on AttributeHelpText.human_attribute_name(:help_text)

      expect(page).to have_current_path(
        attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)
      )

      # Navigate back to details tab
      click_on "Details"

      expect(page).to have_current_path(
        edit_admin_settings_project_custom_field_path(project_custom_field)
      )

      # Navigate back to attribute help text tab
      click_on AttributeHelpText.human_attribute_name(:help_text)

      expect(page).to have_current_path(
        attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)
      )
    end
  end

  describe "help text display uniqueness" do
    it "creates separate help texts for different custom fields" do
      other_custom_field = create(:project_custom_field,
                                  name: "Project Priority",
                                  field_format: "text",
                                  project_custom_field_section:)

      # Create help text for first custom field
      visit attribute_help_text_admin_settings_project_custom_field_path(project_custom_field)
      fill_in "Caption", with: "Rating help"
      editor.set_markdown("Help for rating")
      click_button "Save"

      expect_and_dismiss_flash(message: "Successful update")

      # Create help text for second custom field
      visit attribute_help_text_admin_settings_project_custom_field_path(other_custom_field)
      fill_in "Caption", with: "Priority help"
      editor.set_markdown("Help for priority")
      click_button "Save"

      expect_and_dismiss_flash(message: "Successful update")

      # Verify both help texts exist and are different
      rating_help = AttributeHelpText::Project.find_by(
        attribute_name: "custom_field_#{project_custom_field.id}"
      )
      priority_help = AttributeHelpText::Project.find_by(
        attribute_name: "custom_field_#{other_custom_field.id}"
      )

      expect(rating_help).to be_present
      expect(priority_help).to be_present
      expect(rating_help.id).not_to eq(priority_help.id)
      expect(rating_help.caption).to eq("Rating help")
      expect(priority_help.caption).to eq("Priority help")
    end
  end
end

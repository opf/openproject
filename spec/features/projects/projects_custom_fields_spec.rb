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

RSpec.describe "Projects custom fields", :js, :with_cuprite do
  shared_let(:current_user) { create(:admin) }
  shared_let(:project) { create(:project, name: "Foo project", identifier: "foo-project") }
  let(:name_field) { FormFields::InputFormField.new :name }
  let(:identifier) { "[data-qa-field-name='customField#{custom_field.id}'] input[type=checkbox]" }

  before do
    login_as current_user
  end

  describe "with version CF" do
    let!(:custom_field) do
      create(:version_project_custom_field)
    end
    let(:cf_field) { FormFields::SelectFormField.new custom_field }

    it "allows creating a new project (regression #29099)" do
      visit new_project_path

      name_field.set_value "My project name"

      find(".op-fieldset--toggle", text: "ADVANCED SETTINGS").click

      cf_field.expect_visible

      click_button "Save"

      expect(page).to have_current_path /\/projects\/my-project-name\/?/
    end
  end

  describe "with default values" do
    let!(:default_int_custom_field) do
      create(:integer_project_custom_field, default_value: 123)
    end
    let!(:default_string_custom_field) do
      create(:string_project_custom_field, default_value: "lorem")
    end
    let!(:no_default_string_custom_field) do
      create(:string_project_custom_field)
    end

    let(:name_field) { FormFields::InputFormField.new :name }
    let(:default_int_field) { FormFields::InputFormField.new default_int_custom_field }
    let(:default_string_field) { FormFields::InputFormField.new default_string_custom_field }
    let(:no_default_string_field) { FormFields::InputFormField.new no_default_string_custom_field }

    it "sets the default values on custom fields and allows overwriting them" do
      visit new_project_path

      name_field.set_value "My project name"
      find(".op-fieldset--toggle", text: "ADVANCED SETTINGS").click

      default_int_field.expect_value default_int_custom_field.default_value.to_s
      default_string_field.expect_value default_string_custom_field.default_value.to_s
      no_default_string_field.expect_value ""

      default_string_field.set_value "Overwritten"

      click_button "Save"

      expect(page).to have_current_path /\/projects\/my-project-name\/?/
      created_project = Project.last

      visit project_settings_general_path(created_project)

      default_int_field.expect_value default_int_custom_field.default_value.to_s
      default_string_field.expect_value "Overwritten"

      # The custom field without default value should not be shown
      # as it didn't got activated with a value during project creation
      expect(page).to have_no_css("[data-qa-field-name='customField#{no_default_string_custom_field.id}']")
    end
  end

  describe "with long text CF" do
    let!(:custom_field) do
      create(:text_project_custom_field)
    end
    let(:editor) { Components::WysiwygEditor.new "[data-qa-field-name='customField#{custom_field.id}']" }

    before do
      # enable the custom field for the project
      project.project_custom_fields << custom_field
    end

    it "allows settings the project boolean CF (regression #26313)" do
      visit project_settings_general_path(project.id)

      # expect CF, description and status description ckeditor-augmented-textarea
      expect(page).to have_css(".op-ckeditor--wrapper", count: 3)

      # single hash autocomplete
      editor.insert_link "http://example.org/link with spaces"

      sleep 2

      # Save project settings
      click_on "Save"

      expect(page).to have_text I18n.t("js.notice_successful_update")

      project.reload
      cv = project.custom_values.find_by(custom_field_id: custom_field.id).value

      expect(cv).to include "[http://example.org/link with spaces](http://example.org/link%20with%20spaces)"
      expect(page).to have_css('a[href="http://example.org/link with spaces"]')
    end
  end

  describe "with float CF" do
    let!(:float_cf) do
      create(:float_project_custom_field, name: "MyFloat")
    end
    let(:float_field) { FormFields::InputFormField.new float_cf }

    context "with english locale" do
      let(:current_user) { create(:admin, language: "en") }

      it "displays the float with english locale" do
        visit new_project_path

        name_field.set_value "My project name"
        find(".op-fieldset--toggle", text: "ADVANCED SETTINGS").click

        float_field.set_value "10000.55"

        # Save project settings
        click_on "Save"

        expect(page).to have_current_path /\/projects\/my-project-name\/?/
        project = Project.find_by(name: "My project name")
        cv = project.custom_values.find_by(custom_field_id: float_cf.id).typed_value
        expect(cv).to eq 10000.55

        visit project_settings_general_path(project)
        float_field.expect_value "10000.55"
      end
    end

    context "with german locale",
            driver: :firefox_de,
            with_cuprite: false do
      let(:current_user) { create(:admin, language: "de") }

      it "displays the float with german locale" do
        I18n.locale = :de

        visit new_project_path

        name_field.set_value "My project name"
        find(".op-fieldset--toggle", text: I18n.t("js.forms.advanced_settings").upcase).click

        float_field.set_value "10000,55"

        # Save project settings
        click_on I18n.t("js.button_save")

        expect(page).to have_current_path /\/projects\/my-project-name\/?/
        project = Project.find_by(name: "My project name")
        cv = project.custom_values.find_by(custom_field_id: float_cf.id).typed_value
        expect(cv).to eq 10000.55

        visit project_settings_general_path(project)
        # The field renders in german locale, but there's no way to test that
        # as the internal value is always english locale
        float_field.expect_value "10000.55"
      end
    end
  end

  describe "with boolean CF" do
    let!(:custom_field) do
      create(:boolean_project_custom_field)
    end

    before do
      # enable the custom field for the project
      project.project_custom_fields << custom_field
    end

    it "allows settings the project boolean CF (regression #26313)" do
      visit project_settings_general_path(project.id)
      field = page.find(identifier)
      expect(field).not_to be_checked

      field.check

      click_on "Save"
      expect(page).to have_text I18n.t(:notice_successful_update)

      field = page.find(identifier)
      expect(field).to be_checked
    end
  end

  describe "with user CF" do
    let!(:custom_field) do
      create(:user_project_custom_field)
    end
    let(:cf_field) { FormFields::SelectFormField.new custom_field }

    # Create a second project for visible options
    let!(:existing_project) { create(:project) }

    # Assume one user is visible
    let!(:invisible_user) { create(:user, firstname: "Invisible", lastname: "User") }
    let!(:visible_user) do
      create(:user, firstname: "Visible", lastname: "User",
                    member_with_permissions: { existing_project => %i[view_work_packages edit_work_packages] })
    end

    let(:role) { create(:project_role) }

    let(:modal) do
      Components::Users::InviteUserModal.new project:,
                                             principal: invisible_user,
                                             role:,
                                             invite_message: "you are invited"
    end

    it "allows setting a visible user CF (regression #26313)" do
      visit new_project_path

      name_field.set_value "My project name"

      find(".op-fieldset--toggle", text: "ADVANCED SETTINGS").click

      cf_field.expect_visible
      cf_field.expect_no_option invisible_user
      cf_field.select_option visible_user

      click_on "Save"

      expect(page).to have_current_path /\/projects\/my-project-name\/?/
      project = Project.find_by(name: "My project name")
      cv = project.custom_values.find_by(custom_field_id: custom_field.id).typed_value
      expect(cv).to eq visible_user
    end

    it "allows inviting a new user immediately (regression #39166)" do
      project.project_custom_fields << custom_field # enable the custom field for the project

      visit project_settings_general_path(project.id)

      cf_field.expect_visible
      cf_field.expect_no_option invisible_user

      # Invite the other user to the project
      find(".ng-dropdown-footer button", text: "Invite", wait: 5).click
      modal.run_all_steps

      sleep 2

      # The newly invited user can be directly selected
      cf_field.expect_visible
      cf_field.search("invis")
      cf_field.select_option invisible_user

      click_on "Save"
      expect(page).to have_text I18n.t(:notice_successful_update)

      project.reload
      cv = project.custom_values.find_by(custom_field_id: custom_field.id).typed_value
      expect(cv).to eq invisible_user
    end

    it "does not show invite user button when there is no project selected" do
      visit new_project_path

      name_field.set_value "My project name"

      find(".op-fieldset--toggle", text: "ADVANCED SETTINGS").click

      cf_field.expect_visible
      cf_field.expect_no_option invisible_user
      expect(page).to have_no_css(".ng-dropdown-footer button", text: "Invite")
    end
  end
end

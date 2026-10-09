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

RSpec.describe "User settings administration", :js do
  let(:firstname) { "Ada" }
  let(:lastname) { "Administrator" }
  let(:user_settings_page) { Pages::Admin::Settings::Users.new }
  let(:consent_info_editor) { Components::WysiwygEditor.new }

  current_user { create(:admin, firstname:, lastname:) }

  it "renders the form with all settings" do
    user_settings_page.visit!

    expect(page).to have_heading "User settings"

    within_fieldset "Default preferences" do
      expect(page).to have_select "Default language"
      expect(page).to have_select "Users default time zone"
      expect(page).to have_field "Automatically hide success banners"
    end

    within_fieldset "Display format" do
      expect(page).to have_select "Users name format"
    end

    within_fieldset "Account" do
      expect(page).to have_field "Users allowed to change their email address"
    end

    within_fieldset "Deletion" do
      expect(page).to have_field "User accounts deletable by admins"
      expect(page).to have_field "Users allowed to delete their accounts"
    end

    within_fieldset "User Consent" do
      expect(page).to have_field "Consent required"
      expect(page).to have_select "Consent information text", selected: "English"
      expect(consent_info_editor.editor_element).to have_text("agree to the privacy and security policy")
      expect(page).to have_field "Consent time"
      expect(page).to have_field "Consent contact mail address"
    end

    expect(page).to have_button "Save"
  end

  context "when changing preferences" do
    it "allows changing the default preferences" do
      user_settings_page.visit!

      within_fieldset "Default preferences" do
        expect(page).to have_select "Default language", selected: "English"
        expect(page).to have_field "Users default time zone", with: ""
        expect(page).to have_unchecked_field "Automatically hide success banners"

        select "Deutsch", from: "Default language"
        select "Berlin", from: "Users default time zone"
        check "Automatically hide success banners"
      end

      user_settings_page.save_and_reload!

      within_fieldset "Default preferences" do
        expect(page).to have_select "Default language", selected: "Deutsch"
        expect(page).to have_field "Users default time zone", with: "Europe/Berlin"
        expect(page).to have_checked_field "Automatically hide success banners"
      end
    end

    it "allows changing the users name format" do
      user_settings_page.visit!

      within_fieldset "Display format" do
        expect(page).to have_select "Users name format", selected: "#{firstname} #{lastname}"

        select "#{lastname}, #{firstname}", from: "Users name format"
      end

      user_settings_page.save_and_reload!

      within_fieldset "Display format" do
        expect(page).to have_select "Users name format", selected: "#{lastname}, #{firstname}"
      end
    end

    it "allows changing the account and deletion settings" do
      user_settings_page.visit!

      expect(page).to have_checked_field "Users allowed to change their email address"
      expect(page).to have_unchecked_field "User accounts deletable by admins"
      expect(page).to have_unchecked_field "Users allowed to delete their accounts"

      uncheck "Users allowed to change their email address"
      check "User accounts deletable by admins"
      check "Users allowed to delete their accounts"

      user_settings_page.save_and_reload!

      expect(page).to have_unchecked_field "Users allowed to change their email address"
      expect(page).to have_checked_field "User accounts deletable by admins"
      expect(page).to have_checked_field "Users allowed to delete their accounts"
    end

    it "allows changing the consent settings" do
      user_settings_page.visit!

      within_fieldset "User Consent" do
        expect(page).to have_unchecked_field "Consent required"
        expect(consent_info_editor.editor_element).to have_text("agree to the privacy and security policy")
        expect(page).to have_checked_field "toggle_consent_time"
        expect(page).to have_text "Last update of consent: Never"
        expect(page).to have_field "Consent contact mail address", with: ""

        check "Consent required"
        consent_info_editor.set_markdown("Please accept our updated terms.")
        select "Deutsch", from: "Consent information text"
        consent_info_editor.set_markdown("Bitte stimmen Sie den neuen Bedingungen zu.")
        fill_in "Consent contact mail address", with: "privacy@example.com"
      end

      user_settings_page.save_and_reload!

      within_fieldset "User Consent" do
        expect(page).to have_checked_field "Consent required"
        expect(page).to have_select "Consent information text", selected: "English"
        expect(consent_info_editor.editor_element).to have_text("Please accept our updated terms.", exact: true)

        select "Deutsch", from: "Consent information text"
        expect(consent_info_editor.editor_element).to have_text("Bitte stimmen Sie den neuen Bedingungen zu.", exact: true)

        expect(page).to have_unchecked_field "toggle_consent_time"
        expect(page).to have_no_text "Last update of consent: Never"
        expect(page).to have_field "Consent contact mail address", with: "privacy@example.com"
      end
    end
  end
end

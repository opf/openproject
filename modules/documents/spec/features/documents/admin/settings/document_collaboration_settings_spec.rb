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

RSpec.describe "Document collaboration settings admin",
               :js,
               :settings_reset do
  include Flash::Expectations

  current_user { create(:admin) }

  context "when first time setup" do
    it "can configure hocuspocus url and secret", without_env: ["OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET"] do
      visit admin_settings_document_collaboration_settings_path

      within_test_selector("collaboration-settings-disabled-notice") do
        expect(page).to have_heading("Real-time collaboration is not enabled")
        expect(page).to have_content("Once enabled, multiple users will be able to work together on a " \
                                     "document at the same time. All new documents will be based on a new " \
                                     "editor (BlockNote) and will require a working connection to a Hocuspocus server.")
        click_on "Enable real-time collaboration"
      end

      expect_and_dismiss_flash(message: "Real-time collaboration has been enabled.")

      expect(page).to have_field("Hocuspocus server URL", with: "")
      expect(page).to have_field("Client secret", with: "")

      fill_in "Hocuspocus server URL", with: "wss://hocuspocus.example.com"
      fill_in "Client secret", with: "supersecret"

      click_on("Save")

      expect_and_dismiss_flash(message: "Successful update.")

      expect(page).to have_field("Hocuspocus server URL", with: "wss://hocuspocus.example.com")
      expect(page).to have_field("Client secret", with: "") # Secret is not exposed on forms

      setting_url = Setting.find_by(name: "collaborative_editing_hocuspocus_url")
      setting_secret = Setting.find_by(name: "collaborative_editing_hocuspocus_secret")
      expect(setting_url.value).to eq("wss://hocuspocus.example.com")
      expect(setting_secret.value).to eq("supersecret")

      # Now disable text collaboration
      click_on "Disable"

      within_dialog("Disable real-time collaboration") do
        expect(page).to have_heading "Disable real-time collaboration?"
        expect(page).to have_content "All existing documents may become inaccessible. " \
                                     "Please only do this if you are certain you want to " \
                                     "disable real-time collaboration and the BlockNote editor in this instance."

        check "I understand that I might permanently lose data"

        click_on "Disable"
      end

      expect_and_dismiss_flash(message: "Real-time collaboration has been disabled.")
    end
  end

  context "when submitting an invalid URL scheme",
          with_settings: {
            real_time_text_collaboration_enabled: true,
            collaborative_editing_hocuspocus_url: "wss://hocuspocus.example.com",
            collaborative_editing_hocuspocus_secret: "secret1234"
          } do
    it "rejects https:// URLs and shows inline validation error" do
      visit admin_settings_document_collaboration_settings_path

      fill_in "Hocuspocus server URL", with: "https://hocuspocus.example.com"
      click_on("Save")

      # Inline validation shown on the field
      expect(page).to have_content("Must use a WebSocket protocol (ws:// or wss://).")

      # Setting unchanged
      expect(Setting.collaborative_editing_hocuspocus_url).to eq("wss://hocuspocus.example.com")
    end
  end

  context "with hocuspocus url set via environment variable",
          with_env: { "OPENPROJECT_COLLABORATIVE_EDITING_HOCUSPOCUS_URL" => "wss://env-hocuspocus.example.com" },
          with_settings: { collaborative_editing_hocuspocus_secret: "secret1234" },
          without_env: ["OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET"] do
    before do
      reset(:collaborative_editing_hocuspocus_url)
      visit admin_settings_document_collaboration_settings_path
    end

    it "shows the url as read-only" do
      expect(page).to have_content("Some values are configured via environment variables and cannot be edited here.")

      expect(page).to have_field("Hocuspocus server URL",
                                 with: "wss://env-hocuspocus.example.com",
                                 disabled: true)

      expect(page).to have_field("Client secret",
                                 with: "",
                                 disabled: false)
    end
  end

  context "with an invalid URL scheme set via environment variable",
          with_env: { "OPENPROJECT_COLLABORATIVE_EDITING_HOCUSPOCUS_URL" => "https://env-hocuspocus.example.com" },
          with_settings: { collaborative_editing_hocuspocus_secret: "secret1234" } do
    before do
      reset(:collaborative_editing_hocuspocus_url)
      visit admin_settings_document_collaboration_settings_path
    end

    it "shows an inline validation error on the URL field" do
      expect(page).to have_field("Hocuspocus server URL",
                                 with: "https://env-hocuspocus.example.com",
                                 disabled: true)
      expect(page).to have_content("Must use a WebSocket protocol")
    end
  end

  context "with secret set via environment variable",
          with_env: { "OPENPROJECT_COLLABORATIVE_EDITING_HOCUSPOCUS_SECRET" => "envsupersecret" },
          with_settings: { collaborative_editing_hocuspocus_url: "wss://env-hocuspocus.example.com" } do
    before do
      reset(:collaborative_editing_hocuspocus_secret)
      visit admin_settings_document_collaboration_settings_path
    end

    it "shows the secret as read-only" do
      expect(page).to have_content("Some values are configured via environment variables and cannot be edited here.")

      expect(page).to have_field("Hocuspocus server URL",
                                 with: "wss://env-hocuspocus.example.com",
                                 disabled: false)
      expect(page).to have_field("Client secret",
                                 with: "",
                                 disabled: true)
    end
  end

  context "with both url and secret set via environment variables",
          with_env: {
            "OPENPROJECT_COLLABORATIVE_EDITING_HOCUSPOCUS_URL" => "wss://env-hocuspocus.example.com",
            "OPENPROJECT_COLLABORATIVE_EDITING_HOCUSPOCUS_SECRET" => "envsupersecret"
          } do
    before do
      reset(:collaborative_editing_hocuspocus_url)
      reset(:collaborative_editing_hocuspocus_secret)
      visit admin_settings_document_collaboration_settings_path
    end

    it "shows both fields as read-only" do
      expect(page).to have_content("These values are configured via environment variables and cannot be edited here.")

      expect(page).to have_field("Hocuspocus server URL",
                                 with: "wss://env-hocuspocus.example.com",
                                 disabled: true)
      expect(page).to have_field("Client secret",
                                 with: "",
                                 disabled: true)
    end

    it "does not show a save button" do
      expect(page).to have_no_button(I18n.t("button_save"))
    end
  end

  context "with non-admin user" do
    current_user { create(:user) }

    it "is not accessible" do
      visit admin_settings_document_collaboration_settings_path

      expect(page).to have_content("You are not authorized to access this page.")
    end
  end
end

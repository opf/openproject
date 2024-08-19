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
require_module_spec_helper

RSpec.describe "Admin Create a new file storage",
               :js,
               :storage_server_helpers do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }

  current_user { admin }

  context "with Nextcloud Storage" do
    let(:secret) { "awesome_secret" }

    before do
      allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate).and_return(secret)
    end

    it "renders a Nextcloud specific multi-step form", :webmock do
      visit admin_settings_storages_path

      expect(page).to be_axe_clean.within "#content"

      within(".SubHeader") do
        page.find_test_selector("storages-create-new-provider-button").click
        within_test_selector("storages-select-provider-action-menu") { click_on("Nextcloud") }
      end

      expect(page).to have_current_path(select_provider_admin_settings_storages_path(provider: "nextcloud"))

      aggregate_failures "Select provider view" do
        # Page Header
        expect(page).to have_test_selector("storage-new-page-header--title", text: "New Nextcloud storage")
        expect(page).to have_test_selector("storage-new-page-header--description",
                                           text: "Read our documentation on setting up a Nextcloud file storage " \
                                                 "integration for more information.")

        # General information
        expect(page).to have_test_selector("storage-provider-configuration-instructions",
                                           text: "Please make sure you have administration privileges in your " \
                                                 "Nextcloud instance and the application “Integration OpenProject” " \
                                                 "is installed before doing the setup.")

        # OAuth application
        expect(page).to have_test_selector("storage-openproject-oauth-label", text: "OpenProject OAuth")
        expect(page).not_to have_test_selector("label-openproject_oauth_application_configured-status")

        # OAuth client
        wait_for(page).to have_test_selector("storage-oauth-client-label", text: "Nextcloud OAuth")
        expect(page).not_to have_test_selector("label-storage_oauth_client_configured-status")
        expect(page).to have_test_selector("storage-oauth-client-id-description",
                                           text: "Allow OpenProject to access Nextcloud data using OAuth.")

        # Automatically managed project folders
        expect(page).to have_test_selector("storage-managed-project-folders-label",
                                           text: "Automatically managed folders")
        expect(page).not_to have_test_selector("label-managed-project-folders-status")
        expect(page).to have_test_selector("storage-automatically-managed-project-folders-description",
                                           text: "Let OpenProject create folders per project automatically.")
      end

      aggregate_failures "General information" do
        within_test_selector("storage-general-info-form") do
          fill_in "Name", with: "My Nextcloud", fill_options: { clear: :backspace }
          click_on "Save and continue"

          expect(page).to have_text("Host is not a valid URL.")

          mock_server_capabilities_response("https://example.com")
          mock_server_config_check_response("https://example.com")
          fill_in "Host", with: "https://example.com"
          click_on "Save and continue"
        end

        expect(page).to have_test_selector("label-host_name_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-description", text: "Nextcloud - My Nextcloud - https://example.com")
      end

      aggregate_failures "OAuth application" do
        within_test_selector("storage-openproject-oauth-application-form") do
          warning_section = find_test_selector("storage-openproject_oauth_application_warning")
          expect(warning_section).to have_text("The client secret value will not be accessible again after you close " \
                                               "this window. Please copy these values into the Nextcloud " \
                                               "OpenProject Integration settings.")
          expect(warning_section).to have_link("Nextcloud OpenProject Integration settings",
                                               href: "https://example.com/settings/admin/openproject")

          storage = Storages::NextcloudStorage.find_by(host: "https://example.com/")
          expect(page).to have_css("#openproject_oauth_application_uid",
                                   value: storage.reload.oauth_application.uid)
          expect(page).to have_css("#openproject_oauth_application_secret",
                                   value: secret)

          click_on "Done, continue"
        end
      end

      aggregate_failures "OAuth Client" do
        within_test_selector("storage-oauth-client-form") do
          expect(page).to have_test_selector("storage-provider-credentials-instructions",
                                             text: "Copy these values from Nextcloud Administration / OpenProject.")

          # With null values, form should render inline errors
          expect(page).to have_css("#oauth_client_client_id", value: "")
          expect(page).to have_css("#oauth_client_client_secret", value: "")
          click_on "Save and continue"

          expect(page).to have_text("Client ID can't be blank.")
          expect(page).to have_text("Client secret can't be blank.")

          # Happy path - Submit valid values
          fill_in "Nextcloud OAuth Client ID", with: "1234567890"
          fill_in "Nextcloud OAuth Client Secret", with: "0987654321"
          click_on "Save and continue"
        end

        expect(page).to have_test_selector("label-storage_oauth_client_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-oauth-client-id-description", text: "OAuth Client ID: 1234567890")
      end

      aggregate_failures "Automatically managed project folders" do
        within_test_selector("storage-automatically-managed-project-folders-form") do
          automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatic_management_enabled]"]')
          application_password_input = page.find_by_id("storages_nextcloud_storage_password")
          expect(automatically_managed_switch).to be_checked
          expect(application_password_input.value).to be_empty

          # Clicking submit with application password empty should show an error
          click_on("Done, complete setup")
          expect(page).to have_text("Password can't be blank.")

          # Test the error path for an invalid storage password.
          # Mock a valid response (=401) for example.com, so the password validation should fail
          mock_nextcloud_application_credentials_validation("https://example.com", password: "1234567890",
                                                                                   response_code: 401)
          automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatic_management_enabled]"]')
          expect(automatically_managed_switch).to be_checked
          fill_in "Application password", with: "1234567890"
          # Clicking submit with application password empty should show an error
          click_on("Done, complete setup")
          expect(page).to have_text("Password is not valid.")

          # Test the happy path for a valid storage password.
          # Mock a valid response (=200) for example.com, so the password validation should succeed
          # Fill in application password and submit
          mock_nextcloud_application_credentials_validation("https://example.com", password: "1234567890")
          automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatic_management_enabled]"]')
          expect(automatically_managed_switch).to be_checked
          fill_in "Application password", with: "1234567890"
          click_on("Done, complete setup")
        end

        expect(page).to have_current_path(edit_admin_settings_storage_path(Storages::Storage.last))
        expect(page).to have_test_selector(
          "primer-banner-message-component",
          text: "Storage connected successfully! Remember to activate the module and the specific " \
                "storage in the project settings of each desired project to use it."
        )
      end
    end
  end

  context "with OneDrive Storage and enterprise token missing", with_ee: false do
    it "renders enterprise icon and redirects to upsale", :webmock do
      visit admin_settings_storages_path

      within(".SubHeader") do
        page.find_test_selector("storages-create-new-provider-button").click

        within_test_selector("storages-select-provider-action-menu") do
          expect(page).to have_css(".octicon-op-enterprise-addons")
          click_on("OneDrive/SharePoint")
        end
      end

      expect(page).to have_current_path(upsale_admin_settings_storages_path)
      wait_for(page).to have_text("OneDrive/SharePoint integration")
    end
  end

  context "with OneDrive Storage", with_ee: %i[one_drive_sharepoint_file_storage] do
    it "renders a One Drive specific multi-step form", :webmock do
      visit admin_settings_storages_path

      expect(page).to be_axe_clean.within "#content"

      within(".SubHeader") do
        page.find_test_selector("storages-create-new-provider-button").click
        within_test_selector("storages-select-provider-action-menu") { click_on("OneDrive/SharePoint") }
      end

      expect(page).to have_current_path(select_provider_admin_settings_storages_path(provider: "one_drive"))

      aggregate_failures "Select provider view" do
        # Page Header
        expect(page).to have_test_selector("storage-new-page-header--title", text: "New OneDrive/SharePoint storage")
        expect(page).to have_test_selector("storage-new-page-header--description",
                                           text: "Read our documentation on setting up a OneDrive/SharePoint " \
                                                 "file storage integration for more information.")

        # General information
        expect(page).to have_test_selector("storage-provider-configuration-instructions",
                                           text: "Please make sure you have administration privileges in the " \
                                                 "Azure portal or contact your Microsoft administrator before " \
                                                 "doing the setup. In the portal, you also need to register an " \
                                                 "Azure application or use an existing one for authentication.")

        # Access Management
        wait_for(page).to have_test_selector("access-management-label", text: "Access management")
        expect(page).not_to have_test_selector("label-access_management_configured-status")
        expect(page).to have_text("Select the type of management of user access and folder creation.")
        expect(page).to have_test_selector("access-management-description",
                                           text: "Select the type of management of user access and folder creation.")

        # OAuth client
        wait_for(page).to have_test_selector("storage-oauth-client-label", text: "Azure OAuth")
        expect(page).not_to have_test_selector("label-storage_oauth_client_configured-status")
        expect(page).to have_test_selector("storage-oauth-client-id-description",
                                           text: "Allow OpenProject to access Azure data using OAuth " \
                                                 "to connect OneDrive/Sharepoint.")
        expect(page).to have_test_selector("storage-redirect-uri-description",
                                           text: "Complete the setup with the correct URI redirection.")
      end

      aggregate_failures "General information" do
        within_test_selector("storage-general-info-form") do
          fill_in "Name", with: "My OneDrive", fill_options: { clear: :backspace }
          fill_in "Directory (tenant) ID", with: "029d4741-a4be-44c6-a8e4-e4eff7b19f65"
          click_on "Save and continue"

          expect(page).to have_text("Drive ID can't be blank.")

          fill_in "Drive ID", with: "1234567890"
          click_on "Save and continue"

          expect(page).to have_text("Drive ID is too short (minimum is 17 characters).")

          fill_in "Drive ID", with: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw"
          click_on "Save and continue"
        end

        wait_for(page).to have_test_selector("label-name_configured-storage_tenant_drive_configured-status",
                                             text: "Completed")
        expect(page).to have_test_selector("storage-description", text: "OneDrive/SharePoint - My OneDrive")
      end

      aggregate_failures "Access Management" do
        within_test_selector("storage-access-management-form") do
          expect(page).to have_test_selector("storage-access-management-description",
                                             text: "Select the type of management of user access and folder " \
                                                   "creation. We recommend to use the Automatically managed access " \
                                                   "to have a more organised structure and guarantee access to all " \
                                                   "relevant users.")
          expect(page).to have_checked_field("Automatically managed access and folders")
          expect(page).to have_unchecked_field("Manually managed access and folders")

          choose "Manually managed access and folders"
          click_on "Save and continue"
        end

        wait_for(page).to have_test_selector("label-access_management_configured-status", text: "Completed")
        expect(page).to have_test_selector("access-management-description", text: "Manually managed access and folders")
      end

      aggregate_failures "OAuth Client" do
        within_test_selector("storage-oauth-client-form") do
          expect(page).to have_test_selector("storage-provider-credentials-instructions",
                                             text: "Copy these values from the desired application in the " \
                                                   "Azure portal.")

          # With null values, upon submit validation errors are show
          expect(page).to have_css("#oauth_client_client_id", value: "")
          expect(page).to have_css("#oauth_client_client_secret", value: "")
          click_on "Save and continue"

          expect(page).to have_text("Client ID can't be blank.")
          expect(page).to have_text("Client secret can't be blank.")

          # Happy path - Submit valid values
          fill_in "Azure OAuth Application (client) ID", with: "1234567890"
          fill_in "Azure OAuth Client Secret Value", with: "0987654321"
          expect(find_test_selector("storage-oauth-client-submit-button")).not_to be_disabled
          click_on "Save and continue"

          expect(page).to have_test_selector("storage-oauth-client-redirect-uri")

          click_on "Done, complete setup"
        end

        expect(page).to have_current_path(edit_admin_settings_storage_path(Storages::Storage.last))
        wait_for(page).to have_test_selector(
          "primer-banner-message-component",
          text: "Storage connected successfully! Remember to activate the module and the specific " \
                "storage in the project settings of each desired project to use it."
        )
      end
    end
  end

  describe "Select provider page" do
    context "when navigating directly to the page" do
      it "redirects you back to the index page" do
        visit select_provider_admin_settings_storages_path

        expect(page).to have_current_path(admin_settings_storages_path)
        wait_for(page).to have_text("Please select a valid storage provider.")
      end
    end

    context "when navigating to the page with an invalid provider" do
      it "redirects you back to the index page" do
        visit select_provider_admin_settings_storages_path(provider: "foobar")

        expect(page).to have_current_path(admin_settings_storages_path)
        wait_for(page).to have_text("Please select a valid storage provider.")
      end
    end
  end
end

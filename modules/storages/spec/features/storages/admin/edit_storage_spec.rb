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

RSpec.describe "Admin Edit File storage",
               :js,
               :selenium,
               :storage_server_helpers do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }

  current_user { admin }

  it "renders a danger zone for deletion" do
    storage = create(:nextcloud_storage, name: "Foo Nextcloud")
    visit edit_admin_settings_storage_path(storage)

    page.find_test_selector("storage-delete-button").click

    within_test_selector("op-storages--destroy-confirm-dialog") do
      expect(page).to have_text("Delete file storage")
      expect(page).to have_unchecked_field("I understand that this deletion cannot be reversed")
      expect(page).to have_button("Delete permanently", disabled: true)

      page.check("I understand that this deletion cannot be reversed")
      page.click_button("Delete permanently")
    end

    expect(page).to have_no_text("Foo Nextcloud")
    expect(page).to have_text("Successful deletion.")
    expect(page).to have_current_path(admin_settings_storages_path)
  end

  context "with Two-Way OAuth Nextcloud Storage" do
    let(:storage) { create(:nextcloud_storage, :as_automatically_managed, name: "Cloud Storage") }
    let(:oauth_application) { create(:oauth_application, integration: storage) }
    let(:oauth_client) { create(:oauth_client, integration: storage) }
    let(:secret) { "awesome_secret" }

    before do
      allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate).and_return(secret)
      oauth_application
      oauth_client
    end

    it "renders an edit view", :webmock do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to be_axe_clean
        .within("#content")
        # NB: Heading order is pending app wide update. See https://community.openproject.org/projects/openproject/work_packages/48513
        .skipping("heading-order")

      expect(page).to have_test_selector("storage-new-page-header--title", text: "Cloud Storage (Nextcloud)")

      aggregate_failures "Storage edit view" do
        # General information
        expect(page).to have_test_selector("storage-provider-label", text: "Storage provider")
        expect(page).to have_test_selector("label-host_name_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-description", text: "Nextcloud - #{storage.name} - #{storage.host}")

        # OAuth application
        expect(page).to have_test_selector("storage-openproject-oauth-label", text: "OpenProject OAuth")
        expect(page).to have_test_selector("label-openproject_oauth_application_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-openproject-oauth-application-description",
                                           text: "OAuth Client ID: #{oauth_application.uid}")

        # OAuth client
        expect(page).to have_test_selector("storage-oauth-client-label", text: "Storage OAuth")
        expect(page).to have_test_selector("label-storage_oauth_client_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-oauth-client-id-description",
                                           text: "OAuth Client ID: #{oauth_client.client_id}")

        # Automatically managed project folders
        expect(page).to have_test_selector("storage-managed-project-folders-label",
                                           text: "Automatically managed folders")

        expect(page).to have_test_selector("label-managed-project-folders-status", text: "Active")
        expect(page).to have_test_selector("storage-automatically-managed-project-folders-description",
                                           text: "Let OpenProject create folders per project automatically.")
      end

      aggregate_failures "General information" do
        # Update a storage - happy path
        find_test_selector("storage-edit-host-button").click
        within_test_selector("storage-general-info-form") do
          expect(page).to have_enterprise_banner(:corporate)
          expect(page).to have_css("option:disabled[value=oauth2_sso]") # expect SSO option to be disabled

          fill_in "Name", with: "My Nextcloud"
          click_on "Save and continue"
        end

        expect(page).to have_test_selector("storage-new-page-header--title", text: "My Nextcloud (Nextcloud)")
        expect(page).to have_test_selector("storage-description", text: "Nextcloud - My Nextcloud - #{storage.host}")

        # Update a storage - unhappy path
        find_test_selector("storage-edit-host-button").click
        within_test_selector("storage-general-info-form") do
          fill_in "Name", with: nil
          fill_in "Host", with: nil
          click_on "Save and continue"

          expect(page).to have_text("Name can't be blank.")
          expect(page).to have_text("Host is not a valid URL.")

          click_on "Cancel"
        end
      end

      aggregate_failures "OAuth application" do
        accept_confirm do
          find_test_selector("storage-replace-openproject-oauth-application-button").click
        end

        within_test_selector("storage-openproject-oauth-application-form") do
          warning_section = find_test_selector("storage-openproject_oauth_application_warning")
          expect(warning_section).to have_link("Nextcloud OpenProject Integration settings",
                                               href: "#{storage.host}settings/admin/openproject")

          expect(page).to have_css("#openproject_oauth_application_uid",
                                   value: storage.reload.oauth_application.uid)
          expect(page).to have_css("#openproject_oauth_application_secret",
                                   value: secret)

          click_on "Done, continue"
        end
      end

      aggregate_failures "OAuth Client" do
        accept_confirm do
          find_test_selector("storage-edit-oauth-client-button").click
        end

        within_test_selector("storage-oauth-client-form") do
          # With null values, form should render inline errors
          expect(page).to have_css("#oauth_client_client_id", value: "")
          expect(page).to have_css("#oauth_client_client_secret", value: "")
          click_on "Save and continue"

          expect(page).to have_text("Client ID can't be blank.")
          expect(page).to have_text("Client secret can't be blank.")

          # Happy path - Submit valid values
          fill_in "Nextcloud OAuth Client ID", with: "1234567890"
          fill_in "Nextcloud OAuth Client Secret", with: "0987654321"
          expect(find_test_selector("storage-oauth-client-submit-button")).not_to be_disabled
          click_on "Save and continue"
        end

        expect(page).to have_test_selector("label-storage_oauth_client_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-oauth-client-id-description", text: "OAuth Client ID: 1234567890")
        expect(OAuthClient.where(integration: storage).count).to eq(1)
      end

      aggregate_failures "Automatically managed project folders" do
        find_test_selector("storage-edit-automatically-managed-project-folders-button").click

        within_test_selector("storage-automatically-managed-project-folders-form") do
          automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatic_management_enabled]"]')
          application_password_input = page.find_by_id("storages_nextcloud_storage_password")
          expect(automatically_managed_switch).to be_checked
          expect(application_password_input.value).to be_empty

          # Clicking submit with application password empty should show an error
          click_on("Finish setup")
          expect(page).to have_text("Application password can't be blank.")

          # Test the error path for an invalid storage password.
          # Mock a valid response (=401) for example.com, so the password validation should fail
          mock_nextcloud_application_credentials_validation(storage.host, password: "1234567890",
                                                                          response_code: 401)
          automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatic_management_enabled]"]')
          expect(automatically_managed_switch).to be_checked
          fill_in "Application password", with: "1234567890"
          # Clicking submit with application password empty should show an error
          click_on("Finish setup")
          expect(page).to have_text("Application password is not valid.")

          # Test the happy path for a valid storage password.
          # Mock a valid response (=200) for example.com, so the password validation should succeed
          # Fill in application password and submit
          mock_nextcloud_application_credentials_validation(storage.host, password: "1234567890")
          automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatic_management_enabled]"]')
          expect(automatically_managed_switch).to be_checked
          fill_in "Application password", with: "1234567890"
          click_on("Finish setup")
        end

        expect(page).to have_test_selector("label-managed-project-folders-status", text: "Active")
      end
    end

    it "renders a sidebar component" do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to have_text("Health status report")

      aggregate_failures "Health notifications" do
        expect(page).to have_test_selector("storage-health-status", text: "Pending")
        expect(page).to have_test_selector("email-updates-mode-selector-button", text: "Disable")
        expect(page).to have_test_selector("email-updates-mode-selector",
                                           text: "Admins will receive updates by email when there are important updates.")

        click_on "Disable"

        expect(page).to have_test_selector("email-updates-mode-selector-button", text: "Enable")
        expect(page).to have_test_selector("email-updates-mode-selector",
                                           text: "Admins will not receive updates by email when there are important updates.")
      end
    end
  end

  context "with OAuth 2.0 SSO Nextcloud Storage" do
    let(:storage) do
      create(
        :nextcloud_storage,
        :as_automatically_managed,
        authentication_method: "oauth2_sso",
        storage_audience: "",
        name: "Cloud Storage"
      )
    end
    let(:secret) { "awesome_secret" }

    before do
      allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate).and_return(secret)
    end

    it "renders an edit view", :webmock do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to be_axe_clean
        .within("#content")
        # NB: Heading order is pending app wide update. See https://community.openproject.org/projects/openproject/work_packages/48513
        .skipping("heading-order")

      expect(page).to have_test_selector("storage-new-page-header--title", text: "Cloud Storage (Nextcloud)")

      aggregate_failures "Storage edit view" do
        # General information
        expect(page).to have_test_selector("storage-provider-label", text: "Storage provider")
        expect(page).to have_test_selector("label-host_name_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-description", text: "Nextcloud - #{storage.name} - #{storage.host}")

        # Token Exchange
        expect(page).to have_test_selector("storage-audience-label", text: "Token Exchange")
        expect(page).to have_test_selector("label-storage_audience_configured-status", text: "Incomplete")
        expect(page).to have_test_selector("storage-audience-description", text: "No audience has been configured")

        # Automatically managed project folders
        expect(page).to have_test_selector("storage-managed-project-folders-label",
                                           text: "Automatically managed folders")

        expect(page).to have_test_selector("label-managed-project-folders-status", text: "Active")
        expect(page).to have_test_selector("storage-automatically-managed-project-folders-description",
                                           text: "Let OpenProject create folders per project automatically.")
      end

      # Only testing interaction with components not tested
      # in Two-Way OAuth 2.0 case

      aggregate_failures "General information" do
        find_test_selector("storage-edit-host-button").click
        within_test_selector("storage-general-info-form") do
          # We use a previously configured SSO storage, even though our current token does not support it
          expect(page).to have_enterprise_banner(:corporate)
        end
      end

      aggregate_failures "Token Exchange" do
        find_test_selector("storage-edit-storage-audience-button").click
        within_test_selector("storage-audience-form") do
          expect(page).to have_checked_field("Manually specify audience for which to exchange access token")
          expect(page).to have_field("Storage Audience")

          click_on "Save and continue"
          expect(page).to have_text("Storage Audience can't be blank")

          fill_in "Storage Audience", with: "schmaudience"

          choose("Use access token obtained during user log in")
          expect(page).to have_no_field("Storage Audience")
          choose("Manually specify audience for which to exchange access token")
          expect(page).to have_field("Storage Audience", with: "schmaudience")

          click_on "Save and continue"
        end

        expect(page).to have_test_selector("label-storage_audience_configured-status", text: "Completed")
        expect(page).to have_test_selector(
          "storage-audience-description",
          text: "Exchanging tokens for audience \"schmaudience\""
        )

        find_test_selector("storage-edit-storage-audience-button").click
        within_test_selector("storage-audience-form") do
          expect(page).to have_checked_field("Manually specify audience for which to exchange access token")
          expect(page).to have_field("Storage Audience", with: "schmaudience")

          choose("Use access token obtained during user log in")
          click_on "Save and continue"
        end

        expect(page).to have_test_selector("label-storage_audience_configured-status", text: "Completed")
        expect(page).to have_test_selector(
          "storage-audience-description",
          text: "Using access token obtained by identity provider during login, regardless of audience."
        )

        find_test_selector("storage-edit-storage-audience-button").click
        within_test_selector("storage-audience-form") do
          expect(page).to have_checked_field("Use access token obtained during user log in")
          expect(page).to have_no_field("Storage Audience")

          choose("Manually specify audience for which to exchange access token")
          expect(page).to have_field("Storage Audience", with: "")
        end
      end
    end

    it "renders a sidebar component" do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to have_text("Health status report")

      aggregate_failures "Health notifications" do
        expect(page).to have_test_selector("storage-health-status", text: "Pending")

        expect(page).to have_test_selector("email-updates-mode-selector-button", text: "Disable")
        expect(page).to have_test_selector("email-updates-mode-selector",
                                           text: "Admins will receive updates by email when there are important updates.")

        click_on "Disable"

        expect(page).to have_test_selector("email-updates-mode-selector-button", text: "Enable")
        expect(page).to have_test_selector("email-updates-mode-selector",
                                           text: "Admins will not receive updates by email when there are important updates.")
      end
    end

    context "and when there is an appropriate enterprise token", with_ee: [:nextcloud_sso] do
      it "shows no enterprise banner", :webmock do
        visit edit_admin_settings_storage_path(storage)

        find_test_selector("storage-edit-host-button").click
        within_test_selector("storage-general-info-form") do
          expect(page).not_to have_enterprise_banner
        end
      end
    end
  end

  context "with Nextcloud Storage and not automatically managed" do
    let(:storage) { create(:nextcloud_storage, :as_not_automatically_managed, name: "Cloud Storage") }

    it "renders health status information but without health notifications for automatically managed folders" do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to have_text("Health status report")
      expect(page).not_to have_test_selector("storage-health-status")
      expect(page).not_to have_test_selector("storage-health-notifications-button")
    end
  end

  context "with OneDrive Storage" do
    let(:storage) { create(:one_drive_storage, :as_automatically_managed, name: "Test Drive") }
    let(:oauth_client) { create(:oauth_client, integration: storage) }

    before { oauth_client }

    it "renders an edit view", :webmock do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to be_axe_clean
        .within("#content")
        .skipping("heading-order")

      expect(page).to have_test_selector("storage-new-page-header--title", text: "Test Drive (OneDrive)")

      aggregate_failures "Storage edit view" do
        # General information
        expect(page).to have_test_selector("storage-provider-label", text: "Storage provider")
        expect(page).to have_test_selector("label-name_configured-storage_tenant_drive_configured-status",
                                           text: "Completed")
        expect(page).to have_test_selector("storage-description", text: "OneDrive - Test Drive")

        # OAuth client
        expect(page).to have_test_selector("storage-oauth-client-label", text: "Azure OAuth")
        expect(page).to have_test_selector("label-storage_oauth_client_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-oauth-client-id-description",
                                           text: "OAuth Client ID: #{oauth_client.client_id}")
      end

      aggregate_failures "General information" do
        # Update a storage - happy path
        find_test_selector("storage-edit-host-button").click
        within_test_selector("storage-general-info-form") do
          fill_in "Name", with: "My OneDrive"
          click_on "Save and continue"
        end

        expect(page).to have_test_selector("storage-new-page-header--title", text: "My OneDrive (OneDrive)")
        expect(page).to have_test_selector("storage-description", text: "OneDrive - My OneDrive")

        # Update a storage - unhappy path
        find_test_selector("storage-edit-host-button").click
        within_test_selector("storage-general-info-form") do
          fill_in "Name", with: nil
          fill_in "Drive ID", with: nil
          click_on "Save and continue"

          expect(page).to have_text("Name can't be blank.")
          expect(page).to have_text("Drive ID can't be blank.")

          click_on "Cancel"
        end
      end

      aggregate_failures "OAuth Client" do
        accept_confirm do
          find_test_selector("storage-edit-oauth-client-button").click
        end

        within_test_selector("storage-oauth-client-form") do
          # With null values, form should render inline errors
          expect(page).to have_css("#oauth_client_client_id", value: "")
          expect(page).to have_css("#oauth_client_client_secret", value: "")
          click_on "Save and continue"

          expect(page).to have_text("Client ID can't be blank.")
          expect(page).to have_text("Client secret can't be blank.")

          # Happy path - Submit valid values
          fill_in "Azure OAuth Application (client) ID", with: "1234567890"
          fill_in "Azure OAuth Client Secret Value", with: "0987654321"
          click_on "Save and continue"
        end

        aggregate_failures "Redirect URI" do
          expect(page).to have_test_selector("storage-redirect-uri-label")
          expect(page).to have_test_selector("storage-show-redirect-uri-button")
          expect(page).not_to have_test_selector("storage-oauth-client-redirect-uri")

          find('a[data-test-selector="storage-show-redirect-uri-button"]').click

          expect(page).to have_test_selector("storage-oauth-client-redirect-uri")
          expect(find_test_selector("storage-oauth-client-submit-button")).to be_disabled
        end

        expect(page).to have_test_selector("label-storage_oauth_client_configured-status", text: "Completed")
        expect(page).to have_test_selector("storage-oauth-client-id-description", text: "OAuth Client ID: 1234567890")
      end
    end

    it "renders a sidebar component" do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to have_text("Health status report")

      aggregate_failures "Health notifications" do
        expect(page).to have_test_selector("storage-health-status", text: "Pending")

        expect(page).to have_test_selector("email-updates-mode-selector-button", text: "Disable")
        expect(page).to have_test_selector("email-updates-mode-selector",
                                           text: "Admins will receive updates by email when there are important updates.")

        click_on "Disable"

        expect(page).to have_test_selector("email-updates-mode-selector-button", text: "Enable")
        expect(page).to have_test_selector("email-updates-mode-selector",
                                           text: "Admins will not receive updates by email when there are important updates.")
      end
    end
  end

  context "with OneDrive Storage and not automatically managed" do
    let(:storage) { create(:one_drive_storage, :as_not_automatically_managed, name: "Cloud Storage") }

    it "renders health status information but without health notifications for automatically managed folders" do
      visit edit_admin_settings_storage_path(storage)

      expect(page).to have_text("Health status report")
      expect(page).not_to have_test_selector("storage-health-status")
      expect(page).not_to have_test_selector("storage-health-notifications-button")
    end
  end
end

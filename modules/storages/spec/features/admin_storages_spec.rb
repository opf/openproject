# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require_module_spec_helper

RSpec.describe 'Admin storages',
               :js,
               :storage_server_helpers do
  let(:admin) { create(:admin) }

  before { login_as admin }

  describe 'File storages list' do
    context 'with storages' do
      let(:complete_storage) { create(:nextcloud_storage_with_local_connection) }
      let(:incomplete_storage) { create(:nextcloud_storage) }

      before do
        complete_storage
        incomplete_storage
      end

      it 'renders a list of storages' do
        visit admin_settings_storages_path

        expect(page).to have_css('[data-test-selector="storage-name"]', text: complete_storage.name)
        expect(page).to have_css('[data-test-selector="storage-name"]', text: incomplete_storage.name)
        expect(page).to have_css("a[role='button'][aria-label='Add new storage'][href='#{new_admin_settings_storage_path}']",
                                 text: 'Storage')

        within "li#storages_nextcloud_storage_#{complete_storage.id}" do
          expect(page).not_to have_css('[data-test-selector="label-incomplete"]')
          expect(page).to have_link(complete_storage.name, href: edit_admin_settings_storage_path(complete_storage))
          expect(page).to have_css('[data-test-selector="storage-creator"]', text: complete_storage.creator.name)
          expect(page).to have_css('[data-test-selector="storage-provider"]', text: 'Nextcloud')
          expect(page).to have_css('[data-test-selector="storage-host"]', text: complete_storage.host)
        end

        within "li#storages_nextcloud_storage_#{incomplete_storage.id}" do
          expect(page).to have_css('[data-test-selector="label-incomplete"]')
          expect(page).to have_css('[data-test-selector="storage-name"]', text: incomplete_storage.name)
          expect(page).to have_css('[data-test-selector="storage-provider"]', text: 'Nextcloud')
          expect(page).to have_css('[data-test-selector="storage-host"]', text: incomplete_storage.host)
          expect(page).to have_css('.op-principal--name', text: incomplete_storage.creator.name)
        end
      end
    end

    context 'with no storages' do
      it 'renders a blank slate' do
        visit admin_settings_storages_path

        # Show empty storages list
        expect(page).to have_title('File storages')
        expect(page.find('.PageHeader-title')).to have_text('File storages')
        expect(page).to have_text("You don't have any storages yet.")
        # Show Add storage buttons
        expect(page).to have_css("a[role='button'][aria-label='Add new storage'][href='#{new_admin_settings_storage_path}']",
                                 text: 'Storage').twice
      end
    end
  end

  describe 'New file storage' do
    context 'with Nextcloud Storage' do
      let(:secret) { 'awesome_secret' }

      before do
        allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate).and_return(secret)
      end

      it 'renders a Nextcloud specific multi-step form', :webmock do
        visit admin_settings_storages_path

        within('.blankslate') { click_link("Storage") }
        expect(page).to have_current_path(new_admin_settings_storage_path)

        aggregate_failures 'Select provider view' do
          # General information
          expect(page).to have_select('storages_storage[provider_type]', with_options: %w[Nextcloud OneDrive/SharePoint])
          expect(find_test_selector('storage-select-provider-submit-button')).to be_disabled

          # Select Nextcloud
          select('Nextcloud', from: 'storages_storage[provider_type]')

          # OAuth application
          expect(page).to have_test_selector('storage-openproject-oauth-label', text: 'OpenProject OAuth')
          expect(page).to have_test_selector('label-openproject_oauth_application_configured-status', text: 'Incomplete')

          # OAuth client
          wait_for(page).to have_test_selector('storage-oauth-client-label', text: 'Nextcloud OAuth')
          expect(page).to have_test_selector('label-storage_oauth_client_configured-status', text: 'Incomplete')
          expect(page).to have_test_selector('storage-oauth-client-id-description',
                                             text: "Allow OpenProject to access Nextcloud data using OAuth.")

          # Automatically managed project folders
          expect(page).to have_test_selector('storage-managed-project-folders-label',
                                             text: 'Automatically managed folders')
          expect(page).to have_test_selector('label-managed-project-folders-status', text: 'Incomplete')
          expect(page).to have_test_selector('storage-automatically-managed-project-folders-description',
                                             text: 'Let OpenProject create folders per project automatically.')
        end

        aggregate_failures 'General information' do
          within_test_selector('storage-general-info-form') do
            fill_in 'storages_nextcloud_storage_name', with: 'My Nextcloud', fill_options: { clear: :backspace }
            click_button 'Save and continue'

            expect(page).to have_text("Host is not a valid URL.")

            mock_server_capabilities_response("https://example.com")
            mock_server_config_check_response("https://example.com")
            fill_in 'storages_nextcloud_storage_host', with: 'https://example.com'
            click_button 'Save and continue'
          end

          expect(page).to have_test_selector('label-host_name_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-description', text: "Nextcloud - My Nextcloud - https://example.com")
        end

        aggregate_failures 'OAuth application' do
          within_test_selector('storage-openproject-oauth-application-form') do
            warning_section = find_test_selector('storage-openproject_oauth_application_warning')
            expect(warning_section).to have_text('The client secret value will not be accessible again after you close ' \
                                                 'this window. Please copy these values into the Nextcloud ' \
                                                 'OpenProject Integration settings.')
            expect(warning_section).to have_link('Nextcloud OpenProject Integration settings',
                                                 href: "https://example.com/settings/admin/openproject")

            storage = Storages::NextcloudStorage.find_by(host: 'https://example.com')
            expect(page).to have_css('#openproject_oauth_application_uid',
                                     value: storage.reload.oauth_application.uid)
            expect(page).to have_css('#openproject_oauth_application_secret',
                                     value: secret)

            click_link 'Done, continue'
          end
        end

        aggregate_failures 'OAuth Client' do
          within_test_selector('storage-oauth-client-form') do
            expect(page).to have_test_selector('storage-provider-credentials-instructions',
                                               text: 'Copy these values from Nextcloud Administration / OpenProject.')

            # With null values, submit button should be disabled
            expect(page).to have_css('#oauth_client_client_id', value: '')
            expect(page).to have_css('#oauth_client_client_secret', value: '')
            expect(find_test_selector('storage-oauth-client-submit-button')).to be_disabled

            # Happy path - Submit valid values
            fill_in 'oauth_client_client_id', with: '1234567890'
            fill_in 'oauth_client_client_secret', with: '0987654321'
            expect(find_test_selector('storage-oauth-client-submit-button')).not_to be_disabled
            click_button 'Save and continue'
          end

          expect(page).to have_test_selector('label-storage_oauth_client_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-oauth-client-id-description', text: "OAuth Client ID: 1234567890")
        end

        aggregate_failures 'Automatically managed project folders' do
          within_test_selector('storage-automatically-managed-project-folders-form') do
            automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
            application_password_input = page.find_by_id('storages_nextcloud_storage_password')
            expect(automatically_managed_switch).to be_checked
            expect(application_password_input.value).to be_empty

            # Clicking submit with application password empty should show an error
            click_button('Done, complete setup')
            expect(page).to have_text("Password can't be blank.")

            # Test the error path for an invalid storage password.
            # Mock a valid response (=401) for example.com, so the password validation should fail
            mock_nextcloud_application_credentials_validation('https://example.com', password: "1234567890",
                                                                                     response_code: 401)
            automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
            expect(automatically_managed_switch).to be_checked
            fill_in 'storages_nextcloud_storage_password', with: "1234567890"
            # Clicking submit with application password empty should show an error
            click_button('Done, complete setup')
            expect(page).to have_text("Password is not valid.")

            # Test the happy path for a valid storage password.
            # Mock a valid response (=200) for example.com, so the password validation should succeed
            # Fill in application password and submit
            mock_nextcloud_application_credentials_validation('https://example.com', password: "1234567890")
            automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
            expect(automatically_managed_switch).to be_checked
            fill_in 'storages_nextcloud_storage_password', with: "1234567890"
            click_button('Done, complete setup')
          end

          expect(page).to have_current_path(admin_settings_storages_path)
          expect(page).to have_text("Storage connected successfully! Remember to activate the module and the specific " \
                                    "storage in the project settings of each desired project to use it.")
        end
      end
    end

    context 'with OneDrive Storage' do
      it 'renders a One Drive specific multi-step form', :webmock do
        visit admin_settings_storages_path

        within('.PageHeader') { click_link("Storage") }
        expect(page).to have_current_path(new_admin_settings_storage_path)

        aggregate_failures 'Select provider view' do
          # General information
          expect(page).to have_select('storages_storage[provider_type]', with_options: %w[Nextcloud OneDrive/SharePoint])
          expect(find_test_selector('storage-select-provider-submit-button')).to be_disabled

          # Select OneDrive
          select('OneDrive/SharePoint', from: 'storages_storage[provider_type]')

          # OAuth client
          wait_for(page).to have_test_selector('storage-oauth-client-label', text: 'Azure OAuth')
          expect(page).to have_test_selector('label-storage_oauth_client_configured-status', text: 'Incomplete')
          expect(page).to have_test_selector('storage-oauth-client-id-description',
                                             text: "Allow OpenProject to access Azure data using OAuth " \
                                                   "to connect OneDrive/Sharepoint.")
        end

        aggregate_failures 'General information' do
          within_test_selector('storage-general-info-form') do
            fill_in 'storages_one_drive_storage_name', with: 'My OneDrive', fill_options: { clear: :backspace }
            click_button 'Save and continue'

            expect(page).to have_text("Drive can't be blank.")

            fill_in 'storages_one_drive_storage_drive_id', with: '1234567890'
            click_button 'Save and continue'
          end

          wait_for(page).to have_test_selector('label-host_name_configured-storage_tenant_drive_configured-status',
                                               text: 'Completed')
          expect(page).to have_test_selector('storage-description', text: 'OneDrive/SharePoint - My OneDrive')
        end

        aggregate_failures 'OAuth Client' do
          within_test_selector('storage-oauth-client-form') do
            expect(page).to have_test_selector('storage-provider-credentials-instructions',
                                               text: 'Copy these values from the Azure application. ' \
                                                     'After that, copy the redirect URI back to the Azure application.')

            # With null values, submit button should be disabled
            expect(page).to have_css('#oauth_client_client_id', value: '')
            expect(page).to have_css('#oauth_client_client_secret', value: '')
            expect(find_test_selector('storage-oauth-client-submit-button')).to be_disabled

            # Happy path - Submit valid values
            fill_in 'oauth_client_client_id', with: '1234567890'
            fill_in 'oauth_client_client_secret', with: '0987654321'
            expect(find_test_selector('storage-oauth-client-submit-button')).not_to be_disabled
            click_button 'Save and continue'
          end

          expect(page).to have_current_path(admin_settings_storages_path)
          wait_for(page).to have_text("Storage connected successfully! Remember to activate the module and the specific " \
                                      "storage in the project settings of each desired project to use it.")
        end
      end
    end
  end

  describe 'File storage edit view' do
    it 'renders a delete button' do
      storage = create(:nextcloud_storage, name: "Foo Nextcloud")
      visit edit_admin_settings_storage_path(storage)

      storage_delete_button = find_test_selector('storage-delete-button')
      expect(storage_delete_button).to have_text('Delete')

      accept_confirm do
        storage_delete_button.click
      end

      expect(page).to have_current_path(admin_settings_storages_path)
      expect(page).not_to have_text("Foo Nextcloud")
    end

    context 'with Nextcloud Storage' do
      let(:storage) { create(:nextcloud_storage, :as_automatically_managed) }
      let(:oauth_application) { create(:oauth_application, integration: storage) }
      let(:oauth_client) { create(:oauth_client, integration: storage) }
      let(:secret) { 'awesome_secret' }

      before do
        allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate).and_return(secret)
        oauth_application
        oauth_client
      end

      it 'renders an edit view', :webmock do
        visit edit_admin_settings_storage_path(storage)

        expect(page).to have_test_selector('storage-name-title', text: storage.name.capitalize)

        aggregate_failures 'Storage edit view' do
          # General information
          expect(page).to have_test_selector('storage-provider-label', text: 'Storage provider')
          expect(page).to have_test_selector('label-host_name_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-description', text: "Nextcloud - #{storage.name} - #{storage.host}")

          # OAuth application
          expect(page).to have_test_selector('storage-openproject-oauth-label', text: 'OpenProject OAuth')
          expect(page).to have_test_selector('label-openproject_oauth_application_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-openproject-oauth-application-description',
                                             text: "OAuth Client ID: #{oauth_application.uid}")

          # OAuth client
          expect(page).to have_test_selector('storage-oauth-client-label', text: 'Nextcloud OAuth')
          expect(page).to have_test_selector('label-storage_oauth_client_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-oauth-client-id-description',
                                             text: "OAuth Client ID: #{oauth_client.client_id}")

          # Automatically managed project folders
          expect(page).to have_test_selector('storage-managed-project-folders-label',
                                             text: 'Automatically managed folders')

          expect(page).to have_test_selector('label-managed-project-folders-status', text: 'Active')
          expect(page).to have_test_selector('storage-automatically-managed-project-folders-description',
                                             text: 'Let OpenProject create folders per project automatically.')
        end

        aggregate_failures 'General information' do
          # Update a storage - happy path
          find_test_selector('storage-edit-host-button').click
          within_test_selector('storage-general-info-form') do
            expect(page).to have_css('#storages_nextcloud_storage_provider_type[disabled]')

            fill_in 'storages_nextcloud_storage_name', with: 'My Nextcloud'
            click_button 'Save and continue'
          end

          expect(page).to have_test_selector('storage-name-title', text: 'My Nextcloud')
          expect(page).to have_test_selector('storage-description', text: "Nextcloud - My Nextcloud - #{storage.host}")

          # Update a storage - unhappy path
          find_test_selector('storage-edit-host-button').click
          within_test_selector('storage-general-info-form') do
            fill_in 'storages_nextcloud_storage_name', with: nil
            fill_in 'storages_nextcloud_storage_host', with: nil
            click_button 'Save and continue'

            expect(page).to have_text("Name can't be blank.")
            expect(page).to have_text("Host is not a valid URL.")

            click_link 'Cancel'
          end
        end

        aggregate_failures 'OAuth application' do
          accept_confirm do
            find_test_selector('storage-replace-openproject-oauth-application-button').click
          end

          within_test_selector('storage-openproject-oauth-application-form') do
            warning_section = find_test_selector('storage-openproject_oauth_application_warning')
            expect(warning_section).to have_text('The client secret value will not be accessible again after you close ' \
                                                 'this window. Please copy these values into the Nextcloud ' \
                                                 'OpenProject Integration settings.')
            expect(warning_section).to have_link('Nextcloud OpenProject Integration settings',
                                                 href: "#{storage.host}/settings/admin/openproject")

            expect(page).to have_css('#openproject_oauth_application_uid',
                                     value: storage.reload.oauth_application.uid)
            expect(page).to have_css('#openproject_oauth_application_secret',
                                     value: secret)

            click_link 'Done, continue'
          end
        end

        aggregate_failures 'OAuth Client' do
          accept_confirm do
            find_test_selector('storage-edit-oauth-client-button').click
          end

          within_test_selector('storage-oauth-client-form') do
            # With null values, submit button should be disabled
            expect(page).to have_css('#oauth_client_client_id', value: '')
            expect(page).to have_css('#oauth_client_client_secret', value: '')
            expect(find_test_selector('storage-oauth-client-submit-button')).to be_disabled

            # Happy path - Submit valid values
            fill_in 'oauth_client_client_id', with: '1234567890'
            fill_in 'oauth_client_client_secret', with: '0987654321'
            expect(find_test_selector('storage-oauth-client-submit-button')).not_to be_disabled
            click_button 'Save and continue'
          end

          expect(page).to have_test_selector('label-storage_oauth_client_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-oauth-client-id-description', text: "OAuth Client ID: 1234567890")
        end

        aggregate_failures 'Automatically managed project folders' do
          find_test_selector('storage-edit-automatically-managed-project-folders-button').click

          within_test_selector('storage-automatically-managed-project-folders-form') do
            automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
            application_password_input = page.find_by_id('storages_nextcloud_storage_password')
            expect(automatically_managed_switch).to be_checked
            expect(application_password_input.value).to be_empty

            # Clicking submit with application password empty should show an error
            click_button('Done, complete setup')
            expect(page).to have_text("Password can't be blank.")

            # Test the error path for an invalid storage password.
            # Mock a valid response (=401) for example.com, so the password validation should fail
            mock_nextcloud_application_credentials_validation(storage.host, password: "1234567890",
                                                                            response_code: 401)
            automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
            expect(automatically_managed_switch).to be_checked
            fill_in 'storages_nextcloud_storage_password', with: "1234567890"
            # Clicking submit with application password empty should show an error
            click_button('Done, complete setup')
            expect(page).to have_text("Password is not valid.")

            # Test the happy path for a valid storage password.
            # Mock a valid response (=200) for example.com, so the password validation should succeed
            # Fill in application password and submit
            mock_nextcloud_application_credentials_validation(storage.host, password: "1234567890")
            automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
            expect(automatically_managed_switch).to be_checked
            fill_in 'storages_nextcloud_storage_password', with: "1234567890"
            click_button('Done, complete setup')
          end

          expect(page).to have_test_selector('label-managed-project-folders-status', text: 'Active')
        end
      end
    end

    context 'with OneDrive Storage' do
      let(:storage) { create(:one_drive_storage, name: 'Test Drive') }
      let(:oauth_client) { create(:oauth_client, integration: storage) }

      before { oauth_client }

      it 'renders an edit view', :webmock do
        visit edit_admin_settings_storage_path(storage)

        expect(page).to have_test_selector('storage-name-title', text: 'Test Drive')

        aggregate_failures 'Storage edit view' do
          # General information
          expect(page).to have_test_selector('storage-provider-label', text: 'Storage provider')
          expect(page).to have_test_selector('label-host_name_configured-storage_tenant_drive_configured-status',
                                             text: 'Completed')
          expect(page).to have_test_selector('storage-description', text: 'OneDrive/SharePoint - Test Drive')

          # OAuth client
          expect(page).to have_test_selector('storage-oauth-client-label', text: 'Azure OAuth')
          expect(page).to have_test_selector('label-storage_oauth_client_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-oauth-client-id-description',
                                             text: "OAuth Client ID: #{oauth_client.client_id}")
        end

        aggregate_failures 'General information' do
          # Update a storage - happy path
          find_test_selector('storage-edit-host-button').click
          within_test_selector('storage-general-info-form') do
            expect(page).to have_css('#storages_one_drive_storage_provider_type[disabled]')

            fill_in 'storages_one_drive_storage_name', with: 'My OneDrive'
            click_button 'Save and continue'
          end

          expect(page).to have_test_selector('storage-name-title', text: 'My OneDrive')
          expect(page).to have_test_selector('storage-description', text: 'OneDrive/SharePoint - My OneDrive')

          # Update a storage - unhappy path
          find_test_selector('storage-edit-host-button').click
          within_test_selector('storage-general-info-form') do
            fill_in 'storages_one_drive_storage_name', with: nil
            fill_in 'storages_one_drive_storage_drive_id', with: nil
            click_button 'Save and continue'

            expect(page).to have_text("Name can't be blank.")
            expect(page).to have_text("Drive can't be blank.")

            click_link 'Cancel'
          end
        end

        aggregate_failures 'OAuth Client' do
          accept_confirm do
            find_test_selector('storage-edit-oauth-client-button').click
          end

          within_test_selector('storage-oauth-client-form') do
            # With null values, submit button should be disabled
            expect(page).to have_css('#oauth_client_client_id', value: '')
            expect(page).to have_css('#oauth_client_client_secret', value: '')
            expect(find_test_selector('storage-oauth-client-submit-button')).to be_disabled

            # Happy path - Submit valid values
            fill_in 'oauth_client_client_id', with: '1234567890'
            fill_in 'oauth_client_client_secret', with: '0987654321'
            expect(find_test_selector('storage-oauth-client-submit-button')).not_to be_disabled
            click_button 'Save and continue'
          end

          expect(page).to have_test_selector('label-storage_oauth_client_configured-status', text: 'Completed')
          expect(page).to have_test_selector('storage-oauth-client-id-description', text: "OAuth Client ID: 1234567890")
        end
      end
    end
  end

  # skipped to be revised later. broken due to removal of storage_primer_design feature flag
  xit 'creates, edits and deletes storages', :webmock do
    visit admin_settings_storages_path

    ######### Step 1: Begin Create a storage #########
    # Show empty storages list
    expect(page).to have_title('File storages')
    expect(page.find('.title-container')).to have_text('File storages')
    expect(page).to have_text(I18n.t('storages.no_results'))
    page.find('.toolbar .button--icon.icon-add').click

    # Create a storage - happy path
    expect(page).to have_title('New storage')
    expect(page.find('.title-container')).to have_text('New storage')
    expect(page).to have_select('storages_storage[provider_type]', selected: 'Nextcloud')
    expect(page).to have_field('storages_storage[name]', with: 'My storage')

    # Test the happy path for a valid storage server (host).
    # Mock a valid response (=200) for example.com, so the host validation should succeed
    mock_server_capabilities_response("https://example.com")
    mock_server_config_check_response("https://example.com")

    # Setting to "" is needed to avoid receiving "My NextcloudNC 1"
    page.find_by_id('storages_storage_name').set("")
    page.find_by_id('storages_storage_name').set("NC 1")
    page.find_by_id('storages_storage_host').set("https://example.com")
    page.click_button('Save and continue setup')
    ######### Step 1: End Create a storage #########

    ######### Step 2: Begin Show OAuth application #########
    # Show created oauth application
    storage_type = I18n.t('storages.provider_types.nextcloud.name')
    expect(page).to have_title("#{storage_type} #{I18n.t('storages.label_oauth_application_details')}")
    oauth_app_client_id = page.find_by_id('client_id').value
    expect(oauth_app_client_id.length).to eq 43
    expect(page.find_by_id('secret').value.length).to eq 43
    page.find('a.button', text: 'Done. Continue setup').click
    ######### Step 2: End Show OAuth application #########

    ######### Step 3: Begin Add OAuthClient #########
    # Add OAuthClient - Testing a number of different invalid states
    # However, more detailed checks are performed in the service spec.
    expect(page).to have_title("OAuth client details")

    # Set the client_id but leave client_secret empty
    page.find_by_id('oauth_client_client_id').set("0123456789")
    page.click_button('Save')
    # Check that we're still on the same page
    expect(page).to have_title("OAuth client details")

    # Set client_id to be empty but set the client_secret
    page.find_by_id('oauth_client_client_id').set("")
    page.find_by_id('oauth_client_client_secret').set("1234567890")
    page.click_button('Save')
    # Check that we're still on the same page
    expect(page).to have_title("OAuth client details")

    # Both client_id and client_secret valid
    page.find_by_id('oauth_client_client_id').set("0123456789")
    page.find_by_id('oauth_client_client_secret').set("1234567890")
    page.click_button('Save')
    ######### Step 3: End Add OAuthClient #########

    ######### Step 4: Begin Automatically managed project folders #########
    # Nextcloud - Automatically managed project folders settings
    # Switch is checked by default, expects input for password
    expect(page).to have_title("Automatically managed project folders")
    automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
    application_password_input = page.find_by_id('storages_nextcloud_storage_password')
    expect(automatically_managed_switch).to be_checked
    expect(application_password_input.value).to be_empty

    # Clicking submit with application password empty should show an error
    page.click_button('Done, complete setup')
    # Check that we're still on the same page
    expect(page).to have_title("Automatically managed project folders")
    expect(page).to have_content("Password can't be blank.")

    # Test the error path for an invalid storage password.
    # Mock a valid response (=401) for example.com, so the password validation should fail
    mock_nextcloud_application_credentials_validation("https://example.com", password: "1234567890", response_code: 401)
    automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
    expect(automatically_managed_switch).to be_checked
    page.fill_in 'storages_nextcloud_storage_password', with: "1234567890"
    # Clicking submit with application password empty should show an error
    page.click_button('Save')
    # Check that we're still on the same page
    expect(page).to have_title("Automatically managed project folders")
    expect(page).to have_content("Password is not valid.")

    # Test the happy path for a valid storage password.
    # Mock a valid response (=200) for example.com, so the password validation should succeed
    # Fill in application password and submit
    mock_nextcloud_application_credentials_validation("https://example.com", password: "1234567890")
    automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
    expect(automatically_managed_switch).to be_checked
    page.fill_in 'storages_nextcloud_storage_password', with: "1234567890"
    page.click_button('Save')
    expect(page).to have_text("Active")
    expect(page).to have_text("●●●●●●●●●●●●●●●●")
    ######### Step 4: End Automatically managed project folders #########

    # Edit storage again
    expect(page).to have_title("Edit: NC 1")
    expect(page).not_to have_select("storages_storage[provider_type]")
    expect(page).to have_text("NC 1")
    expect(page.find('.title-container')).to have_text('Edit: NC 1')

    # Edit page - With option to replace the OAuth2 client
    # Check presence of a "Replace" link and follow it
    page.find('a', text: 'Replace Nextcloud').click

    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to have_text("Are you sure?")
    page.driver.browser.switch_to.alert.accept

    # The form the new OAuth client shall be empty as we are creating a new one.
    expect(page).not_to have_text("234567")

    page.find_by_id('oauth_client_client_id').set("2345678901")
    page.find_by_id('oauth_client_client_secret').set("3456789012")
    page.click_button('Replace')

    # Check for client_id
    expect(page).to have_text("2345678901")

    # Test the behavior of a failed host validation with code 400 (Bad Request)
    # simulating server not running Nextcloud
    mock_server_capabilities_response("https://other.example.com", response_code: '400')
    page.find_by_id('storages_storage_name').set("Other NC")
    page.find_by_id('storages_storage_host').set("https://other.example.com")
    page.click_button('Save')

    expect(page).to have_title("Edit: Other NC")
    expect(page.find('.title-container')).to have_text('Edit: Other NC')
    expect(page).to have_css('.op-toast--content')
    expect(page).to have_text("error prohibited this Storage from being saved")

    # Edit page - Check for failed Nextcloud Version
    # Test the behavior of a Nextcloud server with major version too low
    mock_server_capabilities_response("https://old.example.com", response_nextcloud_major_version: 18)
    page.find_by_id('storages_storage_name').set("Old NC")
    page.find_by_id('storages_storage_host').set("https://old.example.com")
    page.click_button('Save')

    expect(page).to have_title("Edit: Old NC")
    expect(page).to have_css('.op-toast')
    version_err = I18n.t('activerecord.errors.models.storages/storage.attributes.host.minimal_nextcloud_version_unmet')
    expect(page).to have_text(version_err)

    # Edit page - save working storage
    # Restore the mocked working server example.com
    page.find_by_id('storages_storage_host').set("https://example.com")
    page.find_by_id('storages_storage_name').set("Other NC")
    page.click_button('Save')

    ######### Begin Edit Automatically managed project folders #########
    #
    # Confirm update of host URL with subpath renders correctly Nextcloud/Administration link
    mock_server_capabilities_response("https://example.com/with/subpath")
    mock_server_config_check_response("https://example.com/with/subpath")
    page.find_by_id('storages_storage_host').set("https://example.com/with/subpath")
    page.click_button('Save')

    # Check for updated host URL
    expect(page.find_by_id('storages_storage_host').value).to eq("https://example.com/with/subpath")

    page.find('a', text: 'Edit automatically managed project folders').click

    expect(page).to have_title("Automatically managed project folders")
    automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
    application_password_input = page.find_by_id('storages_nextcloud_storage_password')
    expect(automatically_managed_switch).to be_checked
    expect(application_password_input.value).to be_empty
    expect(application_password_input['placeholder']).to eq("●●●●●●●●●●●●●●●●")
    expect(page).to have_link(
      text: 'Nextcloud Administration / OpenProject',
      href: 'https://example.com/with/subpath/settings/admin/openproject'
    )

    # Clicking submit without inputting new application password should show an error
    page.click_button('Save')
    # Check that we're still on the same page
    expect(page).to have_title("Automatically managed project folders")
    expect(page).to have_content("Password can't be blank.")

    # Switch off automatically managed project folders
    page.find_test_selector('spot-switch-handle').click
    page.click_button('Save')
    expect(page).to have_text("Inactive")
    ######### End Edit Automatically managed project folders #########

    # List of storages
    page.find("#{test_selector('op-breadcrumb')} ol li", text: "File storages").click

    # Delete on List page
    page.find('td.buttons .icon-delete').click

    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to eq(I18n.t('storages.delete_warning.storage'))
    page.driver.browser.switch_to.alert.accept

    expect(page).to have_current_path(admin_settings_storages_path)
    expect(page).not_to have_text("Other NC")
    # Also check that there are no more OAuthClient instances anymore
    expect(OAuthClient.count).to eq(0)
  end

  describe 'configuration checks' do
    let!(:configured_storage) do
      storage = create(:nextcloud_storage)
      create(:oauth_application, integration: storage)
      create(:oauth_client, integration: storage)
      storage
    end
    let!(:unconfigured_storage) { create(:nextcloud_storage) }

    # skipped to be revised later. broken due to removal of storage_primer_design feature flag
    xit 'reports storages that are not configured correctly' do
      visit admin_settings_storages_path

      aggregate_failures 'storages view with configuration checks' do
        configured_storage_table_row = page.find_by_id("storages_nextcloud_storage_#{configured_storage.id}")
        unconfigured_storage_table_row = page.find_by_id("storages_nextcloud_storage_#{unconfigured_storage.id}")

        expect(configured_storage_table_row).not_to have_css('.octicon-alert-fill')
        expect(unconfigured_storage_table_row).to have_css('.octicon-alert-fill')
      end

      aggregate_failures 'individual storage view' do
        within "#storages_nextcloud_storage_#{configured_storage.id}" do
          page.find('td.buttons .icon-edit').click
        end

        expect(page).not_to have_css('.flash.flash-error')

        within(test_selector('op-breadcrumb')) do
          click_link 'File storages'
        end

        within "#storages_nextcloud_storage_#{unconfigured_storage.id}" do
          page.find('td.buttons .icon-edit').click
        end

        expect(page).to have_css('.flash.flash-error', text: 'The setup of this storage is incomplete.')
      end
    end
  end
end

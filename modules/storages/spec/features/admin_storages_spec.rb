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

require_relative '../spec_helper'

RSpec.describe 'Admin storages', :storage_server_helpers, js: true do
  let(:admin) { create(:admin) }

  before do
    login_as admin
  end

  it 'creates, edits and deletes storages', webmock: true do
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
    expect(page).to have_field('storages_storage[name]', with: 'My Nextcloud')

    # Test the happy path for a valid storage server (host).
    # Mock a valid response (=200) for example.com, so the host validation should succeed
    mock_server_capabilities_response("https://example.com")
    mock_server_config_check_response("https://example.com")

    # Setting to "" is needed to avoid receiving "My NextcloudNC 1"
    page.find_by_id('storages_storage_name').set("")
    page.find_by_id('storages_storage_name').set("NC 1")
    page.find_by_id('storages_storage_host').set("https://example.com")
    page.find('button[type=submit]', text: "Save and continue setup").click
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
    page.find('button[type=submit]').click
    # Check that we're still on the same page
    expect(page).to have_title("OAuth client details")

    # Set client_id to be empty but set the client_secret
    page.find_by_id('oauth_client_client_id').set("")
    page.find_by_id('oauth_client_client_secret').set("1234567890")
    page.find('button[type=submit]', text: 'Save').click
    # Check that we're still on the same page
    expect(page).to have_title("OAuth client details")

    # Both client_id and client_secret valid
    page.find_by_id('oauth_client_client_id').set("0123456789")
    page.find_by_id('oauth_client_client_secret').set("1234567890")
    page.find('button[type=submit]', text: 'Save').click
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

    # Show details of a storage
    created_storage = Storages::Storage.find_by(name: 'NC 1')
    expect(page).to have_title("Nc 1")
    expect(page.find('.title-container')).to have_text('NC 1')
    expect(page).to have_text(admin.name)
    expect(page).to have_text('https://example.com')
    expect(page).to have_text(created_storage.created_at.localtime.strftime("%m/%d/%Y %I:%M %p"))
    # Check for client_id of nextcloud client and oauth application
    expect(page).to have_text(oauth_app_client_id)
    expect(page).to have_text("0123456789")
    # Check for the automatically managed project folders settings

    # Edit storage again
    page.find('.button--icon.icon-edit').click
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
    page.find('button[type=submit]', text: 'Replace').click

    # Check for client_id
    expect(page).to have_text("2345678901")

    # Test the behavior of a failed host validation with code 400 (Bad Request)
    # simulating server not running Nextcloud
    page.find('.button--icon.icon-edit').click
    mock_server_capabilities_response("https://other.example.com", response_code: '400')
    page.find_by_id('storages_storage_name').set("Other NC")
    page.find_by_id('storages_storage_host').set("https://other.example.com")
    page.find('button[type=submit]', text: "Save").click

    expect(page).to have_title("Edit: Other NC")
    expect(page.find('.title-container')).to have_text('Edit: Other NC')
    expect(page).to have_selector('.op-toast--content')
    expect(page).to have_text("error prohibited this Storage from being saved")

    # Edit page - Check for failed Nextcloud Version
    # Test the behavior of a Nextcloud server with major version too low
    mock_server_capabilities_response("https://old.example.com", response_nextcloud_major_version: 18)
    page.find_by_id('storages_storage_name').set("Old NC")
    page.find_by_id('storages_storage_host').set("https://old.example.com")
    page.find('button[type=submit]', text: "Save").click

    expect(page).to have_title("Edit: Old NC")
    expect(page).to have_selector('.op-toast')
    version_err = I18n.t('activerecord.errors.models.storages/storage.attributes.host.minimal_nextcloud_version_unmet')
    expect(page).to have_text(version_err)

    # Edit page - save working storage
    # Restore the mocked working server example.com
    page.find_by_id('storages_storage_host').set("https://example.com")
    page.find_by_id('storages_storage_name').set("Other NC")
    page.find('button[type=submit]', text: "Save").click

    created_storage = Storages::Storage.find_by(name: 'Other NC')
    expect(page).to have_title("Other Nc")
    expect(page.find('.title-container')).to have_text('Other NC')
    expect(page).to have_text(admin.name)
    expect(page).to have_text('https://example.com')
    expect(page).to have_text(created_storage.created_at.localtime.strftime("%m/%d/%Y %I:%M %p"))

    ######### Begin Edit Automatically managed project folders #########
    page.find('.button--icon.icon-edit').click

    # Confirm update of host URL with subpath renders correctly Nextcloud/Administration link
    mock_server_capabilities_response("https://example.com/with/subpath")
    mock_server_config_check_response("https://example.com/with/subpath")
    page.find_by_id('storages_storage_host').set("https://example.com/with/subpath")
    page.click_button('Save')

    # Check for updated host URL
    expect(page).to have_text("https://example.com/with/subpath")

    page.find('.button--icon.icon-edit').click
    page.find('a', text: 'Edit automatically managed project folders').click

    expect(page).to have_title("Automatically managed project folders")
    automatically_managed_switch = page.find('[name="storages_nextcloud_storage[automatically_managed]"]')
    application_password_input = page.find_by_id('storages_nextcloud_storage_password')
    expect(automatically_managed_switch).to be_checked
    expect(application_password_input.value).to be_empty
    expect(application_password_input['placeholder']).to eq("●●●●●●●●●●●●●●●●")
    expect(page).to have_link(text: 'Nextcloud Administration / OpenProject', href: 'https://example.com/with/subpath/settings/admin/openproject')

    # Clicking submit without inputing new application password should show an error
    page.click_button('Save')
    # Check that we're still on the same page
    expect(page).to have_title("Automatically managed project folders")
    expect(page).to have_content("Password can't be blank.")

    # Switch off automatically managed project folders
    page.find('[data-qa-selector="spot-switch-handle"]').click
    page.click_button('Save')
    expect(page).to have_text("Inactive")
    ######### End Edit Automatically managed project folders #########

    # List of storages
    page.find("ul.op-breadcrumb li", text: "File storages").click

    # Delete on List page
    page.find('td.buttons .icon-delete').click

    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to eq(I18n.t('storages.delete_warning.storage'))
    page.driver.browser.switch_to.alert.accept

    expect(page).to have_current_path(admin_settings_storages_path)
    expect(page).not_to have_text("Other NC")
    # Also check that there are no more OAuthClient instances anymore
    expect(OAuthClient.all.count).to eq(0)
  end
end

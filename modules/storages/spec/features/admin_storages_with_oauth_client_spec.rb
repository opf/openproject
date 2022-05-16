#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# This test assumes that admin_storages_spec.rb already checked
# the CRUD behavior and validation of Storages.
# This test only checks the OAuthClient part related to Storages.
describe 'Admin storages OAuthClient', :enable_storages, :storage_server_helpers, type: :feature, js: true do
  let(:admin) { create(:admin) }

  before do
    login_as admin
  end

  it 'creates a storage and tests OAuthClient CRUD', webmock: true do
    visit admin_settings_storages_path

    # ---------------------------------------------------------------------
    # List page
    expect(page).to have_title('File storages')
    expect(page).to have_text(I18n.t('storages.no_results'))
    page.find('.toolbar .button--icon.icon-add').click

    # ---------------------------------------------------------------------
    # Create a Storage as a base for testing
    expect(page).to have_title('New storage')
    expect(page).to have_select 'storages_storage[provider_type]', selected: 'Nextcloud', disabled: true
    expect(page).to have_field('storages_storage[name]', with: 'Nextcloud')

    # Mock a valid response (=200) for example.com, so the host validation should succeed
    mock_server_capabilities_response("https://example.com")
    page.find('#storages_storage_name').set("NC 1")
    page.find('#storages_storage_host').set("https://example.com")
    page.find('button[type=submit]').click

    # ---------------------------------------------------------------------
    # Display page - show the created Storage
    created_storage = Storages::Storage.find_by(name: 'NC 1')
    expect(page).to have_title("Nc 1")
    expect(page.find('.title-container')).to have_text('NC 1')
    expect(page).to have_text(admin.name)
    expect(page).to have_text('https://example.com')
    expect(page).to have_text(created_storage.created_at.localtime.strftime("%m/%d/%Y %I:%M %p"))
    page.find('.button--icon.icon-edit').click

    # ---------------------------------------------------------------------
    # Edit page - This is where the Create/Reset buttons for OAuthClient should appear
    expect(page).to have_title("Edit: NC 1")
    expect(page.find('.title-container')).to have_text('Edit: NC 1')

    # Check for present of a "Create" link and follow
    expect(page).to have_text("Create")
    link = page.find('a', text: 'Create')
    link.click

    # ---------------------------------------------------------------------
    # New page for OAuthClient - Test a number of different invalid states
    # However, more detailed checks are performed in the service spec.
    expect(page).to have_title("OAuth client details")

    # ---------------------------------------------------------------------
    # client_id set but client_secret is empty
    page.find('#oauth_client_client_id').set("0123456789")
    page.find('#oauth_client_client_secret').set("")
    page.find('button[type=submit]').click
    # Check that we're still on the same page
    expect(page).to have_title("OAuth client details")

    # ---------------------------------------------------------------------
    # client_id empty but client_secret set
    page.find('#oauth_client_client_id').set("")
    page.find('#oauth_client_client_secret').set("1234567890")
    page.find('button[type=submit]').click
    # Check that we're still on the same page
    expect(page).to have_title("OAuth client details")

    # ---------------------------------------------------------------------
    # Both client_id and client_secret valid
    page.find('#oauth_client_client_id').set("0123456789")
    page.find('#oauth_client_client_secret').set("1234567890")
    page.find('button[type=submit]').click

    # ---------------------------------------------------------------------
    # Show page - Check that the OAuth client details are present
    expect(page).to have_title("File storages")
    expect(page).to have_title("Nc 1")

    # Check for client_id and the shortened client secret
    expect(page).to have_text("0123456789")
    expect(page).to have_text("12****90")
    page.find('.button--icon.icon-edit').click

    # ---------------------------------------------------------------------
    # Edit page - With option to reset the OAuth2 client
    # Check for present of a "Reset" link and follow
    expect(page).to have_text("Reset")
    link = page.find('a', text: 'Reset')
    link.click

    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to have_text("Are you sure?")
    page.driver.browser.switch_to.alert.accept

    # ---------------------------------------------------------------------
    # OAuth client new page - expect empty
    expect(page).not_to have_text("234567")
    expect(page).not_to have_text("****")

    page.find('#oauth_client_client_id').set("2345678901")
    page.find('#oauth_client_client_secret').set("3456789012")
    page.find('button[type=submit]').click

    # ---------------------------------------------------------------------
    # Delete
    page.find('.button--icon.icon-delete').click

    # ---------------------------------------------------------------------
    # List page with no entries anymore
    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to eq(I18n.t('storages.delete_warning.storage'))
    page.driver.browser.switch_to.alert.accept

    expect(page).to have_current_path(admin_settings_storages_path)
    expect(page).to have_text(I18n.t('storages.no_results'))
    expect(page).not_to have_text("Other NC")
    # Also check that there are no more OAuthClient instances anymore
    expect(OAuthClient.all.count).to eq(0)
  end
end

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

describe 'Admin storages', :enable_storages, :storage_server_helpers, type: :feature, js: true do
  let(:admin) { create(:admin) }

  before do
    login_as admin
  end

  it 'creates, edits and deletes storages', webmock: true do
    visit admin_settings_storages_path
    expect(page).to have_title('File storages')
    expect(page.find('.title-container')).to have_text('File storages')
    expect(page).to have_text(I18n.t('storages.no_results'))

    page.find('.toolbar .button--icon.icon-add').click

    expect(page).to have_title('New storage')
    expect(page.find('.title-container')).to have_text('New storage')
    expect(page).to have_select 'storages_storage[provider_type]', selected: 'Nextcloud', disabled: true
    expect(page).to have_field('storages_storage[name]', with: 'Nextcloud')

    mock_server_capabilities_response("https://example.com")
    page.find('#storages_storage_name').set("NC 1")
    page.find('#storages_storage_host').set("https://example.com")
    page.find('button[type=submit]').click

    created_storage = Storages::Storage.find_by(name: 'NC 1')
    expect(page).to have_title("Nc 1")
    expect(page.find('.title-container')).to have_text('NC 1')
    expect(page).to have_text(admin.name)
    expect(page).to have_text('https://example.com')
    expect(page).to have_text(created_storage.created_at.localtime.strftime("%m/%d/%Y %I:%M %p"))

    page.find('.button--icon.icon-edit').click

    expect(page).to have_title("Edit: NC 1")
    expect(page.find('.title-container')).to have_text('Edit: NC 1')

    mock_server_capabilities_response("https://other.example.com")
    page.find('#storages_storage_name').set("Other NC")
    page.find('#storages_storage_host').set("https://other.example.com")
    page.find('button[type=submit]').click

    expect(page).to have_title("Other Nc")
    expect(page.find('.title-container')).to have_text('Other NC')
    expect(page).to have_text('https://other.example.com')

    page.find("ul.op-breadcrumb li", text: "File storages").click

    expect(page).to have_title "File storages"
    expect(page.find('.title-container')).to have_text('File storages')
    expect(page).to have_text('Other NC')
    expect(page).to have_text('https://other.example.com')
    expect(page).to have_text(admin.name)

    page.find("a", text: 'Other NC').click
    expect(page).to have_current_path admin_settings_storage_path(created_storage)
    page.find('.button--icon.icon-delete').click

    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to eq(I18n.t('storages.delete_warning.storage'))
    page.driver.browser.switch_to.alert.accept

    expect(page).to have_current_path(admin_settings_storages_path)
    expect(page).not_to have_text("Other NC")
  end
end

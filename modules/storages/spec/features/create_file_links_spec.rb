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

describe 'Creating file links in work package', js: true, webmock: true, with_flag: { storage_file_linking: true } do
  let(:permissions) { %i(view_work_packages edit_work_packages view_file_links manage_file_links) }
  let(:project) { create(:project) }
  let(:current_user) { create(:user, member_in_project: project, member_with_permissions: permissions) }
  let(:work_package) { create(:work_package, project:, description: 'Initial description') }

  let(:oauth_application) { create(:oauth_application) }
  let(:storage) { create(:storage, oauth_application:) }
  let(:oauth_client) { create(:oauth_client, integration: storage) }
  let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user: current_user) }
  let(:project_storage) { create(:project_storage, project:, storage:) }
  let(:file_link) { create(:file_link, container: work_package, storage:, origin_id: '22', origin_name: 'jingle.ogg') }

  let(:connection_manager) do
    connection_manager = instance_double(OAuthClients::ConnectionManager)
    allow(connection_manager).to receive(:refresh_token).and_return(ServiceResult.success(result: oauth_client_token))
    allow(connection_manager).to receive(:get_access_token).and_return(ServiceResult.success(result: oauth_client_token))
    allow(connection_manager).to receive(:authorization_state).and_return(:connected)
    allow(connection_manager).to receive(:request_with_token_refresh).and_yield(oauth_client_token)
    connection_manager
  end

  let(:root_xml_response) { create(:webdav_data) }
  let(:folder1_xml_response) { create(:webdav_data_folder) }

  let(:sync_service) do
    sync_service = instance_double(Storages::FileLinkSyncService)
    allow(sync_service).to receive(:call) do |file_links|
      ServiceResult.success(result: file_links.each { |file_link| file_link.origin_permission = :view })
    end
    sync_service
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:dialog) { Components::FilePickerDialog.new }

  before do
    allow(OAuthClients::ConnectionManager).to receive(:new).and_return(connection_manager)
    allow(Storages::FileLinkSyncService).to receive(:new).and_return(sync_service)

    stub_request(:propfind, "#{storage.host}/remote.php/dav/files/#{oauth_client_token.origin_user_id}")
      .to_return(status: 207, body: root_xml_response, headers: {})
    stub_request(:propfind, "#{storage.host}/remote.php/dav/files/#{oauth_client_token.origin_user_id}/Folder1")
      .to_return(status: 207, body: folder1_xml_response, headers: {})

    project_storage
    file_link

    login_as current_user
    wp_page.visit_tab! :files
  end

  describe 'with the file picker', with_flag: { storage_file_picking_select_all: true, storage_file_linking: true } do
    it 'must enable the user to link existing files on the storage' do
      expect(wp_page.all('[data-qa-selector="file-list--item"]').size).to eq 1
      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: file_link.name)

      wp_page.find('[data-qa-selector="op-storage--link-existing-file-button"]').click

      dialog.expect_open
      dialog.confirm_button_state(selection_count: 0)

      dialog.select_file('Manual.pdf')
      dialog.confirm_button_state(selection_count: 1)

      dialog.enter_folder('Folder1')
      dialog.has_list_item?(text: file_link.name, checked: true, disabled: true)
      dialog.select_all
      dialog.confirm_button_state(selection_count: 3)

      dialog.select_file('notes.txt')
      dialog.confirm_button_state(selection_count: 2)

      dialog.use_breadcrumb(position: 'root')
      dialog.has_list_item?(text: 'Manual.pdf', checked: true, disabled: false)

      dialog.confirm

      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: 'Manual.pdf')
      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: 'logo.png')
      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: file_link.name)
    end
  end
end

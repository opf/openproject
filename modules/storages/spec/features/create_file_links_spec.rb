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

RSpec.describe 'Managing file links in work package', js: true, webmock: true do
  let(:permissions) { %i(view_work_packages edit_work_packages view_file_links manage_file_links) }
  let(:project) { create(:project) }
  let(:current_user) { create(:user, member_in_project: project, member_with_permissions: permissions) }
  let(:work_package) { create(:work_package, project:, description: 'Initial description') }

  let(:oauth_application) { create(:oauth_application) }
  let(:storage) { create(:storage, oauth_application:) }
  let(:oauth_client) { create(:oauth_client, integration: storage) }
  let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user: current_user) }
  let(:project_storage) { create(:project_storage, project:, storage:, project_folder_id: nil, project_folder_mode: 'inactive') }
  let(:file_link) { create(:file_link, container: work_package, storage:, origin_id: '22', origin_name: 'jingle.ogg') }

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
  let(:file_picker) { Components::FilePickerDialog.new }
  let(:confirmation_dialog) { Components::ConfirmationDialog.new }

  before do
    allow(Storages::FileLinkSyncService).to receive(:new).and_return(sync_service)

    stub_request(:get, "#{storage.host}/ocs/v1.php/cloud/user")
      .with(
        headers: {
          'Authorization' => 'Bearer 1234567890-1',
          'Ocs-Apirequest' => 'true',
          'Accept' => "application/json"
        }
      )
      .to_return(status: 200, body: "", headers: {})
    stub_request(:propfind, "#{storage.host}/remote.php/dav/files/#{oauth_client_token.origin_user_id}/")
      .to_return(status: 207, body: root_xml_response, headers: {})
    stub_request(:propfind, "#{storage.host}/remote.php/dav/files/#{oauth_client_token.origin_user_id}/Folder1")
      .to_return(status: 207, body: folder1_xml_response, headers: {})

    project_storage
    file_link

    login_as current_user
    wp_page.visit_tab! :files
  end

  describe 'create with the file picker and delete', with_flag: { storage_file_picking_select_all: true } do
    it 'must enable the user to manage existing files on the storage' do
      expect(wp_page.all('[data-qa-selector="file-list--item"]').size).to eq 1
      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: file_link.name)

      wp_page.find('[data-qa-selector="op-storage--link-existing-file-button"]').click

      file_picker.expect_open
      file_picker.confirm_button_state(selection_count: 0)

      file_picker.select_file('Manual.pdf')
      file_picker.confirm_button_state(selection_count: 1)

      file_picker.enter_folder('Folder1')
      file_picker.has_list_item?(text: file_link.name, checked: true, disabled: true)
      file_picker.select_all
      file_picker.confirm_button_state(selection_count: 3)

      file_picker.select_file('notes.txt')
      file_picker.confirm_button_state(selection_count: 2)

      file_picker.use_breadcrumb(position: 'root')
      file_picker.has_list_item?(text: 'Manual.pdf', checked: true, disabled: false)

      file_picker.confirm

      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: 'Manual.pdf')
      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: 'logo.png')
      expect(wp_page).to have_selector('[data-qa-selector="file-list--item"]', text: file_link.name)
      expect(wp_page.all('[data-qa-selector="file-list--item"]').size).to eq 3

      wp_page.find('[data-qa-selector="file-list--item"]', text: 'logo.png').hover
      wp_page.within('[data-qa-selector="file-list--item"]', text: 'logo.png') do
        wp_page.find('[data-qa-selector="file-list--item-remove-floating-action"]').click
      end

      confirmation_dialog.confirm

      expect(wp_page).not_to have_selector('[data-qa-selector="file-list--item"]', text: 'logo.png')
      expect(wp_page.all('[data-qa-selector="file-list--item"]').size).to eq 2
    end
  end
end

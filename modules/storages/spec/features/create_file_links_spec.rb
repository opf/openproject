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

RSpec.describe "Managing file links in work package", :js, :webmock do
  let(:permissions) { %i(view_work_packages edit_work_packages view_file_links manage_file_links) }
  let(:project) { create(:project) }
  let(:current_user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:, description: "Initial description") }

  let(:oauth_application) { create(:oauth_application) }
  let(:storage) { create(:nextcloud_storage, name: "My Storage", oauth_application:) }
  let(:oauth_client) { create(:oauth_client, integration: storage) }
  let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user: current_user) }
  let(:remote_identity) { create(:remote_identity, oauth_client:, user: current_user, origin_user_id: "admin") }
  let(:project_storage) { create(:project_storage, project:, storage:, project_folder_id: nil, project_folder_mode: "inactive") }
  let(:file_link) { create(:file_link, container: work_package, storage:, origin_id: "22", origin_name: "jingle.ogg") }

  let(:root_xml_response) { create(:webdav_data) }
  let(:folder1_xml_response) { create(:webdav_data_folder) }

  let(:sync_service) do
    sync_service = instance_double(Storages::FileLinkSyncService)
    allow(sync_service).to receive(:call) do |file_links|
      ServiceResult.success(result: file_links.each { |file_link| file_link.origin_status = :view_allowed })
    end
    sync_service
  end

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:modal) { Components::Common::Modal.new }

  before do
    allow(Storages::FileLinkSyncService).to receive(:new).and_return(sync_service)

    Storages::Peripherals::Registry.stub(
      "#{storage.short_provider_type}.queries.auth_check",
      ->(_) { ServiceResult.success }
    )

    stub_request(:propfind, "#{storage.host}remote.php/dav/files/#{remote_identity.origin_user_id}")
      .to_return(status: 207, body: root_xml_response, headers: {})
    stub_request(:propfind, "#{storage.host}remote.php/dav/files/#{remote_identity.origin_user_id}/Folder1")
      .to_return(status: 207, body: folder1_xml_response, headers: {})

    oauth_client_token
    project_storage
    file_link

    login_as current_user
    wp_page.visit_tab! :files
  end

  context "with select all in file picker enabled", with_flag: { storage_file_picking_select_all: true } do
    it "must enable the user to select files from file picker to create file links" do
      within_test_selector("op-tab-content--tab-section", text: "MY STORAGE", wait: 25) do
        expect(page).to have_list_item(count: 1)
        expect(page).to have_list_item(text: "jingle.ogg")
        page.click_on("Link existing files")
      end

      modal.expect_open
      modal.expect_title("Select files")
      modal.within_modal do
        expect(page).to have_button("Select files to link", disabled: true)

        within(:list_item, text: "Manual.pdf") { page.click }

        expect(page).to have_button("Link 1 file", disabled: false)

        within(:list_item, text: "Folder1") { page.click }

        within(:list_item, text: "jingle.ogg") do
          expect(page).to have_field(type: "checkbox", checked: true, disabled: true)
        end

        page.click_on("Select all")
        expect(page).to have_button("Link 3 files", disabled: false)

        within(:list_item, text: "notes.txt") { page.click }
        expect(page).to have_button("Link 2 files", disabled: false)

        page.click_on("My Storage")
        within(:list_item, text: "Manual.pdf") do
          expect(page).to have_field(type: "checkbox", checked: true, disabled: false)
        end

        page.click_on("Link 2 files")
      end

      within_test_selector("op-tab-content--tab-section", text: "MY STORAGE") do
        expect(page).to have_list_item(count: 3)
        expect(page).to have_list_item(text: "jingle.ogg")
        expect(page).to have_list_item(text: "Manual.pdf")
        expect(page).to have_list_item(text: "logo.png")
      end
    end
  end

  it "must enable the user to remove a file link" do
    within_test_selector("op-tab-content--tab-section", text: "MY STORAGE") do
      within(:list_item, text: "jingle.ogg") do
        page.find("span", text: "jingle.ogg").hover
        page.click_on("Remove file link")
      end
    end

    modal.expect_open
    modal.expect_title("Remove file link")
    modal.within_modal do
      page.click_on("Remove link")
    end

    expect(page).not_to have_list_item(text: "jingle.ogg")
  end
end

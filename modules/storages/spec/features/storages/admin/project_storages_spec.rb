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

# We decrease the notification polling interval because some portions of the JS code rely on something triggering
# the Angular change detection. This is usually done by the notification polling, but we don't want to wait
RSpec.describe "Admin lists project mappings for a storage",
               :js,
               :webmock,
               :with_cuprite,
               with_flag: { enable_storage_for_multiple_projects: true },
               with_settings: { notifications_polling_interval: 1_000 } do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  shared_let(:non_admin) { create(:user) }

  shared_let(:project) { create(:project, name: "My active Project") }
  shared_let(:archived_project) { create(:project, active: false, name: "My archived Project") }
  shared_let(:storage) { create(:nextcloud_storage_with_complete_configuration, name: "My Nextcloud Storage") }
  shared_let(:project_storage) { create(:project_storage, project:, storage:, project_folder_mode: "automatic") }

  shared_let(:archived_project_project_storage) do
    create(:project_storage, project: archived_project, storage:, project_folder_mode: "inactive")
  end

  let(:project_storages_index_page) { Pages::Admin::Storages::ProjectStorages::Index.new }

  current_user { admin }


  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit admin_settings_storage_project_storages_path(storage)

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions but an incomplete configured storage" do
    before do
      storage.update!(host: nil)
      login_as(admin)
      visit admin_settings_storage_project_storages_path(storage)
    end

    it "shows a warning instead of the button to add a project and the project list" do
      aggregate_failures("projects list and button are missing") do
        expect(page).to have_no_css("#project-table")
        expect(page).to have_no_text(project.name)
        expect(page).to have_no_button("Add projects")
      end

      aggregate_failures("a warning is shown") do
        expect(page).to have_text("Storage setup incomplete")
        expect(page).to have_text("Please, complete the setup")
      end
    end
  end

  context "with sufficient permissions and an completely configured storage" do
    before do
      login_as(admin)
      storage.update!(host: "https://example.com")

      visit admin_settings_storage_project_storages_path(storage)
    end

    it "renders a list of projects linked to the storage" do
      aggregate_failures "shows a correct breadcrumb menu" do
        within ".PageHeader-breadcrumbs" do
          expect(page).to have_link("Administration")
          expect(page).to have_link("Files")
          expect(page).to have_link("My Nextcloud Storage")
        end
      end

      aggregate_failures "shows tab navigation" do
        within_test_selector("storage_detail_header") do
          expect(page).to have_link("Details")
          expect(page).to have_link("Enabled in projects")
        end
      end

      aggregate_failures "shows the correct table headers" do
        within "#project-table" do
          expect(page)
            .to have_css("th", text: "NAME")
          expect(page)
            .to have_css("th", text: "PROJECT FOLDER TYPE")
        end
      end

      aggregate_failures "shows the correct project mappings including archived projects and their configured folder modes" do
        within "#project-table" do
          project_storages_index_page.within_the_table_row_containing(project.name) do
            expect(page).to have_text("Automatically managed")
          end
          project_storages_index_page.within_the_table_row_containing(archived_project.name) do
            expect(page).to have_text("No specific folder")
          end
        end
      end
    end

    it "shows an error in the dialog when no project is selected before adding" do
      create(:project)
      expect(page).to have_no_css("dialog")
      click_on "Add projects"

      page.within("dialog") do
        click_on "Add"

        wait_for(page).to have_text("Please select a project.")
      end
    end

    it "allows linking a project to a storage" do
      project = create(:project)
      subproject = create(:project, parent: project)
      click_on "Add projects"

      within("dialog") do
        autocompleter = page.find(".op-project-autocompleter")
        autocompleter.fill_in with: project.name

        expect(page).to have_no_text(archived_project.name)

        find(".ng-option-label", text: project.name).click
        check "Include sub-projects"

        expect(page.find_by_id("storages_project_storage_project_folder_mode_automatic")).to be_checked

        click_on "Add"
      end

      expect(page).to have_text(project.name)
      expect(page).to have_text(subproject.name)

      aggregate_failures "pagination links maintain the correct url" do
        within ".op-pagination" do
          pagination_links = page.all(".op-pagination--item-link")
          expect(pagination_links.size).to be_positive

          pagination_links.each do |pagination_link|
            uri = URI.parse(pagination_link["href"])
            expect(uri.path).to eq(admin_settings_storage_project_storages_path(storage))
          end
        end
      end
    end

    describe "Linking a project to a storage with a manually managed folder" do
      context "when the user has granted OAuth access" do
        let(:oauth_client_token) { create(:oauth_client_token, oauth_client: storage.oauth_client, user: admin) }
        let(:remote_identity) do
          create(:remote_identity, oauth_client: storage.oauth_client, user: admin, origin_user_id: "admin")
        end
        let(:location_picker) { Components::FilePickerDialog.new }

        let(:root_xml_response) { build(:webdav_data) }
        let(:folder1_xml_response) { build(:webdav_data_folder) }
        let(:folder1_fileinfo_response) do
          {
            ocs: {
              data: {
                status: "OK",
                statuscode: 200,
                id: 11,
                name: "Folder1",
                path: "files/Folder1",
                mtime: 1682509719,
                ctime: 0
              }
            }
          }
        end

        before do
          oauth_client_token
          remote_identity

          stub_request(:propfind, "#{storage.host}/remote.php/dav/files/#{remote_identity.origin_user_id}")
            .to_return(status: 207, body: root_xml_response, headers: {})
          stub_request(:propfind, "#{storage.host}/remote.php/dav/files/#{remote_identity.origin_user_id}/Folder1")
            .to_return(status: 207, body: folder1_xml_response, headers: {})
          stub_request(:get, "#{storage.host}/ocs/v1.php/apps/integration_openproject/fileinfo/11")
            .to_return(status: 200, body: folder1_fileinfo_response.to_json, headers: {})
          stub_request(:get, "#{storage.host}/ocs/v1.php/cloud/user").to_return(status: 200, body: "{}")
          stub_request(
            :delete,
            "#{storage.host}/remote.php/dav/files/OpenProject/OpenProject/Project%20name%20without%20sequence%20(#{project.id})"
          ).to_return(status: 200, body: "", headers: {})
        end

        it "allows linking a project to a storage" do
          project = create(:project)
          subproject = create(:project, parent: project)
          click_on "Add projects"

          within("dialog") do
            autocompleter = page.find(".op-project-autocompleter")
            autocompleter.fill_in with: project.name

            find(".ng-option-label", text: project.name).click
            check "Include sub-projects"

            expect(page.find_by_id("storages_project_storage_project_folder_mode_automatic")).to be_checked

            choose "Existing folder with manually managed permissions"
            wait_for(page).to have_text("No selected folder")
            click_on "Select folder"

            location_picker.expect_open
            using_wait_time(20) do
              location_picker.wait_for_folder_loaded
              location_picker.enter_folder("Folder1")
              location_picker.wait_for_folder_loaded
            end
            location_picker.confirm

            # Add storage
            expect(page).to have_text("Folder1")

            click_on "Add"
          end

          expect(page).to have_text(project.name)
          expect(page).to have_text(subproject.name)

          aggregate_failures "can edit the project folder" do
            project_storages_index_page.click_menu_item_of("Edit project folder", project)

            within("dialog") do
              choose "No specific folder"
              click_on "Save"
            end

            project_storages_index_page.within_the_table_row_containing(project.name) do
              expect(page).to have_text("No specific folder")
            end
          end
        end

        context "when the user does not select a folder" do
          it "shows an error message" do
            project = create(:project)
            click_on "Add projects"

            within("dialog") do
              autocompleter = page.find(".op-project-autocompleter")
              autocompleter.fill_in with: project.name

              find(".ng-option-label", text: project.name).click
              check "Include sub-projects"

              choose "Existing folder with manually managed permissions"
              wait_for(page).to have_text("No selected folder")

              click_on "Add"

              expect(page).to have_text("Please select a folder.")
              expect(page.find_by_id("storages_project_storage_project_folder_mode_manual")).to be_checked
              expect(page).to have_text("No selected folder")
            end
          end
        end
      end

      context "when the user has not granted oauth access" do
        before do
          OAuthClientToken.where(user: admin, oauth_client: storage.oauth_client).destroy_all
        end

        it "show a storage login button" do
          click_on "Add projects"

          within("dialog") do
            choose "Existing folder with manually managed permissions"
            wait_for(page).to have_button("Nextcloud login")
            click_on("Nextcloud login")
            wait_for(page).to have_current_path(
              %r{/index.php/apps/oauth2/authorize\?client_id=.*&redirect_uri=.*&response_type=code&state=.*}
            )
          end
        end
      end
    end

    describe "Removal of a project from a storage" do
      let(:success_delete_service) do
        Class.new do
          def initialize(user:, model:)
            @user = user
            @model = model
          end

          def call
            @model.destroy!
            ServiceResult.success
          end
        end
      end

      it "shows a warning dialog that can be aborted" do
        expect(page).to have_text(project.name)
        project_storages_index_page.click_menu_item_of("Remove project", project)

        page.within("dialog") do
          expect(page).to have_text("Remove project from Nextcloud")
          expect(page).to have_text("this storage has an automatically managed project folder")
          click_on "Close"
        end

        expect(page).to have_text(project.name)
      end

      it "is possible to remove the project after checking the confirmation checkbox in the dialog" do
        expect(page).to have_text(project.name)
        project_storages_index_page.click_menu_item_of("Remove project", project)

        # The original DeleteService would try to remove actual files from actual storages,
        # which is of course not possible in this test since no real storage is used.
        expect(Storages::ProjectStorages::DeleteService)
          .to receive(:new) # rubocop:disable RSpec/MessageSpies
          .and_wrap_original do |_original_method, *args, &_block|
            user, model = *args.first.values
            success_delete_service.new(user:, model:)
          end

        page.within("dialog") do
          expect(page).to have_button("Remove", disabled: true)
          Retryable.repeat_until_success do
            check "Please, confirm you understand and want to remove this file storage from this project"
            expect(page).to have_button("Remove", disabled: false) # ensure button is clickable
            click_on "Remove"
          end
        end

        expect(page).to have_text("Successful deletion.")
        expect(page).to have_no_text(project.name)
      end
    end
  end
end

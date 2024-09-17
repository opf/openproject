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

# Setup storages in Project -> Settings -> File Storages
# This tests assumes that a Storage has already been setup
# in the Admin section, tested by admin_storage_spec.rb.

# We decrease the notification polling interval because some portions of the JS code rely on something triggering
# the Angular change detection. This is usually done by the notification polling, but we don't want to wait
RSpec.describe("Activation of storages in projects",
               :js, :oauth_connection_helpers, :storage_server_helpers, :webmock, :with_cuprite,
               with_settings: { notifications_polling_interval: 1_000 }) do
  let(:user) { create(:user) }
  # The first page is the Project -> Settings -> General page, so we need
  # to provide the user with the edit_project permission in the role.
  let(:role) do
    create(:project_role,
           permissions: %i[manage_files_in_project
                           select_project_modules
                           edit_project])
  end
  let(:oauth_application) { create(:oauth_application) }
  let(:storage) { create(:nextcloud_storage, :as_automatically_managed, oauth_application:) }
  let(:project) do
    create(:project,
           name: "Project name without sequence",
           members: { user => role },
           enabled_module_names: %i[storages work_package_tracking])
  end

  let(:oauth_client) { create(:oauth_client, integration: storage) }
  let(:oauth_client_token) { create(:oauth_client_token, oauth_client:, user:) }
  let(:remote_identity) { create(:remote_identity, user:, oauth_client:, origin_user_id: "admin") }

  let(:location_picker) { Components::FilePickerDialog.new }

  before do
    oauth_client_token
    storage
    project
    oauth_client_token

    stub_outbound_storage_files_request_for(storage:, remote_identity:)

    login_as(user)
  end

  it "adds, edits and removes storages to projects" do
    # Go to Projects -> Settings -> File Storages
    visit project_settings_general_path(project)
    page.click_on("Files")

    # Check for an empty table in Project -> Settings -> File storages
    expect(page).to have_title("Files")
    expect(page).to have_current_path external_file_storages_project_settings_project_storages_path(project)
    expect(page).to have_text(I18n.t("storages.no_results"))
    page.first(:link, "New storage").click

    # Can cancel the creation of a new file storage
    expect(page).to have_current_path new_project_settings_project_storage_path(project_id: project)
    expect(page).to have_text("Add a file storage")
    page.click_on("Cancel")
    expect(page).to have_current_path external_file_storages_project_settings_project_storages_path(project)

    # Enable one file storage together with a project folder mode
    page.first(:link, "New storage").click
    expect(page).to have_current_path new_project_settings_project_storage_path(project_id: project)
    expect(page).to have_text("Add a file storage")
    expect(page).to have_select("storages_project_storage_storage_id",
                                options: ["#{storage.name} (#{storage.short_provider_type})"])
    page.click_on("Continue")

    # by default automatic have to be choosen if storage has automatic management enabled
    expect(page).to have_checked_field("New folder with automatically managed permissions")

    page.find_by_id("storages_project_storage_project_folder_mode_manual").click

    # Select project folder
    expect(page).to have_text("No selected folder")
    page.click_on("Select folder")
    location_picker.expect_open
    using_wait_time(20) do
      location_picker.wait_for_folder_loaded
      location_picker.enter_folder("Folder1")
      location_picker.wait_for_folder_loaded
    end
    location_picker.confirm

    # Add storage
    expect(page).to have_text("Folder1")
    page.click_on("Add")

    # The list of enabled file storages should now contain Storage 1
    expect(page).to have_css("h1", text: "Files")
    expect(page).to have_text(storage.name)

    # Press Edit icon to change the project folder mode to inactive
    page.find(".icon.icon-edit").click
    path = edit_project_settings_project_storage_path(project_id: project,
                                                      id: Storages::ProjectStorage.last,
                                                      storages_project_storage: { project_folder_mode: "manual" })
    expect(page).to have_current_path(path)
    expect(page).to have_text("Edit the file storage to this project")
    expect(page).to have_no_select("storages_project_storage_storage_id")
    expect(page).to have_text(storage.name)
    expect(page).to have_checked_field("storages_project_storage_project_folder_mode_manual")
    expect(page).to have_text("Folder1")

    # Change the project folder mode to inactive, project folder is hidden but retained
    page.find_by_id("storages_project_storage_project_folder_mode_inactive").click
    expect(page).to have_no_text("Folder1")
    page.click_on("Save")

    # The list of enabled file storages should still contain Storage 1
    expect(page).to have_css("h1", text: "Files")
    expect(page).to have_text(storage.name)

    # Click Edit icon again but cancel the edit
    page.find(".icon.icon-edit").click
    path = edit_project_settings_project_storage_path(project_id: project,
                                                      id: Storages::ProjectStorage.last,
                                                      storages_project_storage: { project_folder_mode: "inactive" })
    expect(page).to have_current_path(path)
    expect(page).to have_text("Edit the file storage to this project")
    page.click_on("Cancel")
    expect(page).to have_current_path external_file_storages_project_settings_project_storages_path(project)

    # Press Delete icon to remove the storage from the project
    page.find(".icon.icon-delete").click

    # Danger zone confirmation flow
    expect(page).to have_css(".form--section-title", text: "DELETE FILE STORAGE")
    expect(page).to have_css(".danger-zone--warning", text: "Deleting a file storage is an irreversible action.")
    expect(page).to have_button("Delete", disabled: true)

    # Cancel Confirmation
    page.click_on("Cancel")
    expect(page).to have_current_path external_file_storages_project_settings_project_storages_path(project)

    page.find(".icon.icon-delete").click

    # Approve Confirmation
    page.fill_in "delete_confirmation", with: storage.name
    page.click_on("Delete")

    # List of ProjectStorages empty again
    expect(page).to have_current_path external_file_storages_project_settings_project_storages_path(project)
    expect(page).to have_text(I18n.t("storages.no_results"))
  end

  describe "automatic project folder mode" do
    context "when the storage is not automatically managed" do
      let(:oauth_application) { create(:oauth_application) }
      let(:storage) { create(:nextcloud_storage, :as_not_automatically_managed, oauth_application:) }
      let(:project_storage) { create(:project_storage, storage:, project:) }

      it "automatic option is not available" do
        visit edit_project_settings_project_storage_path(project_id: project, id: project_storage)

        expect(page).to have_no_content("New folder with automatically managed permissions")
      end
    end

    context "when the storage is automatically managed" do
      let(:oauth_application) { create(:oauth_application) }
      let(:storage) { create(:nextcloud_storage, :as_automatically_managed, oauth_application:) }
      let(:project_storage) { create(:project_storage, storage:, project:) }

      it "automatic option is available" do
        visit edit_project_settings_project_storage_path(project_id: project, id: project_storage)

        expect(page).to have_content("New folder with automatically managed permissions")
      end
    end
  end

  describe "manual project folder mode" do
    context "when the storage is automatically managed" do
      context "when the storage is a nextcloud storage" do
        let(:oauth_application) { create(:oauth_application) }
        let(:storage) { create(:nextcloud_storage, :as_automatically_managed, oauth_application:) }
        let(:project_storage) { create(:project_storage, storage:, project:) }

        it "shows the option for manually managed permissions" do
          visit edit_project_settings_project_storage_path(project_id: project, id: project_storage)

          expect(page).to have_content("Existing folder with manually managed permissions")
        end
      end

      context "when the storage is a one drive storage" do
        let(:oauth_application) { create(:oauth_application) }
        let(:storage) { create(:one_drive_storage, :as_automatically_managed, oauth_application:) }
        let(:project_storage) { create(:project_storage, storage:, project:) }

        before do
          mock_one_drive_authorization_validation
        end

        it "shows no option for manually managed permissions" do
          visit edit_project_settings_project_storage_path(project_id: project, id: project_storage)

          expect(page).to have_no_content("Existing folder with manually managed permissions")
        end
      end
    end
  end

  describe "configuration checks" do
    let(:configured_storage) { storage }
    let!(:unconfigured_storage) { create(:nextcloud_storage) }

    it "excludes storages that are not configured correctly" do
      visit external_file_storages_project_settings_project_storages_path(project)

      page.first(:link, "New storage").click

      aggregate_failures "select field options" do
        expect(page).to have_select("storages_project_storage_storage_id",
                                    options: ["#{configured_storage.name} (#{configured_storage.short_provider_type})"])
        expect(page).to have_no_select("storages_project_storage_storage_id",
                                       options: ["#{unconfigured_storage.name} (#{unconfigured_storage.short_provider_type})"])
      end
    end
  end
end

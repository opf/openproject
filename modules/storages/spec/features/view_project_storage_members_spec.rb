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

RSpec.describe "Project storage members connection status view", :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, members: [group_user]) }
  let(:placeholder_user) { create(:placeholder_user) }
  let(:admin_user) { create(:admin) }
  let(:connected_user) { create(:user) }
  let(:connected_no_permissions_user) { create(:user) }
  let(:disconnected_user) { create(:user) }
  let(:group_user) { create(:user) }

  let!(:storage) { create_nextcloud_storage_with_oauth_application }
  let!(:project) { create_project_with_storage_and_members }
  let!(:project_storage) { create(:project_storage, :as_automatically_managed, project:, storage:) }
  let(:oauth_client) { create(:oauth_client, integration: storage) }

  before do
    create_remote_identities_for_users(oauth_client:,
                                       users: [connected_user, admin_user,
                                               connected_no_permissions_user])
  end

  it "cannot be accessed without being logged in" do
    visit project_settings_project_storage_members_path(project, project_storage_id: project_storage.id)

    expect(page).to have_title("Sign in | OpenProject")
    expect(page).to have_no_text("Members connection status")
  end

  it "lists project members connection statuses" do
    login_as user

    # Go to Projects -> Settings -> File Storages
    visit external_file_storages_project_settings_project_storages_path(project)

    expect(page).to have_title("Files")
    expect(page).to have_text(storage.name)
    page.find(".icon.icon-group").click

    # Members connection status page
    expect(page).to have_current_path project_settings_project_storage_members_path(project_id: project,
                                                                                    project_storage_id: project_storage)

    aggregate_failures "Verifying Connection Statuses" do
      [
        [user, "Not connected. The user should login to the storage via the following link."],
        [admin_user, "Connected"],
        [connected_user, "Connected"],
        [connected_no_permissions_user, "User role has no storages permissions"],
        [disconnected_user, "Not connected. The user should login to the storage via the following link."],
        [group_user, "Not connected. The user should login to the storage via the following link."]
      ].each do |(principal, status)|
        expect(page).to have_css("#member-#{principal.id} .name", text: principal.name)
        expect(page).to have_css("#member-#{principal.id} .status", text: status)
      end

      [placeholder_user, group].each do |principal|
        expect(page).to have_no_css("#member-#{principal.id} .name", text: principal.name)
      end
    end
  end

  it "lists no results when there are no project members" do
    login_as admin_user
    project_no_members = create(:project, enabled_module_names: %i[storages])
    project_storage_no_members = create(:project_storage, :as_automatically_managed, project: project_no_members, storage:)

    # Go to Projects -> Settings -> File Storages
    visit external_file_storages_project_settings_project_storages_path(project_no_members)

    expect(page).to have_title("Files")
    expect(page).to have_text(storage.name)
    page.find(".icon.icon-group").click

    # Members connection status page
    expected_current_path = project_settings_project_storage_members_path(project_id: project_no_members,
                                                                          project_storage_id: project_storage_no_members)
    expect(page).to have_current_path(expected_current_path)

    expect(page).to have_text("No members to display.")
  end

  def create_project_with_storage_and_members
    role_can_read_files = create(:project_role, permissions: %i[manage_files_in_project read_files])
    role_cannot_read_files = create(:project_role, permissions: %i[manage_files_in_project])

    create(:project,
           members: { user => role_can_read_files,
                      admin_user => role_cannot_read_files,
                      connected_user => role_can_read_files,
                      connected_no_permissions_user => role_cannot_read_files,
                      disconnected_user => role_can_read_files,
                      placeholder_user => role_can_read_files,
                      group => role_can_read_files },
           enabled_module_names: %i[storages])
  end

  def create_nextcloud_storage_with_oauth_application
    oauth_application = create(:oauth_application)
    create(:nextcloud_storage, :as_automatically_managed, oauth_application:)
  end

  def create_remote_identities_for_users(oauth_client:, users:)
    users.each do |user|
      create(:remote_identity, oauth_client:, user:, origin_user_id: "origin-user-id-#{user.id}")
    end
  end
end

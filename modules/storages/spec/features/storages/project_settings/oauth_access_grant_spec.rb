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

RSpec.describe "OAuth Access Grant Nudge upon adding a storage to a project",
               :js,
               :webmock do
  shared_let(:user) { create(:user, preferences: { time_zone: "Etc/UTC" }) }

  shared_let(:role) do
    create(:project_role, permissions: %i[manage_files_in_project
                                          oauth_access_grant
                                          select_project_modules
                                          edit_project])
  end

  shared_let(:storage) { create(:nextcloud_storage_with_complete_configuration) }

  shared_let(:project) do
    create(:project,
           name: "Project name without sequence",
           members: { user => role },
           enabled_module_names: %i[storages work_package_tracking])
  end

  current_user { user }

  let(:nonce) { "57a17c3f-b2ed-446e-9dd8-651ba3aec37d" }
  let(:redirect_uri) do
    "#{CGI.escape(OpenProject::Application.root_url)}/oauth_clients/#{storage.oauth_client.client_id}/callback"
  end

  before do
    allow(SecureRandom).to receive(:uuid).and_call_original.ordered
    allow(SecureRandom).to receive(:uuid).and_return(nonce).ordered
  end

  it "adds a storage, nudges the project admin to grant OAuth access" do
    visit external_file_storages_project_settings_project_storages_path(project_id: project)

    click_on("Storage")

    expect(page).to have_select("Storage", options: ["#{storage.name} (nextcloud)"])
    click_on("Continue")

    expect(page).to have_checked_field("New folder with automatically managed permissions")
    click_on("Add")

    expect(page).to have_css("h1", text: "Files")
    expect(page).to have_text(storage.name)

    within_test_selector("oauth-access-grant-nudge-modal") do
      expect(page).to be_axe_clean
      expect(page).to have_text("Login to Nextcloud required")
      click_on("Nextcloud log in")
      wait_for(page).to have_current_path("/index.php/apps/oauth2/authorize?client_id=#{storage.oauth_client.client_id}&" \
                                          "redirect_uri=#{redirect_uri}&response_type=code&state=#{nonce}")
    end
  end

  it "edits a storage, nudges the project admin to grant OAuth access" do
    project_storage = create(:project_storage, project:, storage:)

    visit edit_project_settings_project_storage_path(project_id: project, id: project_storage)

    expect(page).to have_text("Edit the file storage to this project")

    click_on "Save"

    within_test_selector("oauth-access-grant-nudge-modal") do
      expect(page).to be_axe_clean
      expect(page).to have_text("Login to Nextcloud required")
      click_on("Nextcloud log in")
      wait_for(page).to have_current_path("/index.php/apps/oauth2/authorize?client_id=#{storage.oauth_client.client_id}&" \
                                          "redirect_uri=#{redirect_uri}&response_type=code&state=#{nonce}")
    end
  end
end

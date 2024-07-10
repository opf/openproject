# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "Admin lists project mappings for a storage",
               :js,
               :storage_server_helpers,
               with_flag: { enable_storage_for_multiple_projects: true } do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  shared_let(:non_admin) { create(:user) }
  shared_let(:project) { create(:project, name: "My active Project") }
  shared_let(:archived_project) { create(:project, active: false, name: "My archived Project") }
  shared_let(:storage) { create(:nextcloud_storage, name: "My Nextcloud Storage") }
  shared_let(:project_storage) { create :project_storage, project:, storage: }
  shared_let(:archived_project_project_storage) { create :project_storage, project: archived_project, storage: }

  current_user { admin }

  context "with insufficient permissions" do
    it "is not accessible" do
      login_as(non_admin)
      visit admin_settings_storage_project_storages_path(storage)

      expect(page).to have_text("You are not authorized to access this page.")
    end
  end

  context "with sufficient permissions" do
    before do
      login_as(admin)
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

      aggregate_failures "shows the correct project mappings" do
        within "#project-table" do
          expect(page).to have_text(project.name)
          expect(page).to have_text(archived_project.name)
        end
      end
    end
  end
end

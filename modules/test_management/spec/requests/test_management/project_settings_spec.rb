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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Test management project settings", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  describe "PATCH /projects/:id/test_management/project_settings" do
    context "with manage_test_management" do
      let(:user) do
        create(:user,
               member_with_permissions: {
                 project => %i[view_test_cases manage_test_management]
               })
      end

      before { login_as(user) }

      it "updates prefix and navigation layout" do
        patch project_test_management_project_settings_path(project),
              params: {
                project_setting: {
                  display_prefix: "TC",
                  navigation_layout: "horizontal"
                }
              }

        expect(response).to redirect_to(project_test_management_project_settings_path(project))
        setting = TestManagement::ProjectSetting.find_by!(project:)
        expect(setting.display_prefix).to eq("TC")
        expect(setting.effective_navigation_layout).to eq("horizontal")
        expect(setting.options).to include("navigation_layout" => "horizontal")
      end

      it "updates navigation layout when display prefix is blank" do
        patch project_test_management_project_settings_path(project),
              params: {
                project_setting: {
                  display_prefix: "",
                  navigation_layout: "horizontal"
                }
              }

        expect(response).to redirect_to(project_test_management_project_settings_path(project))
        expect(TestManagement::ProjectSetting.find_by!(project:).effective_navigation_layout).to eq("horizontal")
      end

      it "updates navigation layout even when options still hold removed feature keys" do
        create(:tm_project_setting, project:, options: { "enable_ci" => true, "folder_tree_layout" => "split_pane" })

        patch project_test_management_project_settings_path(project),
              params: { project_setting: { navigation_layout: "horizontal" } }

        expect(response).to redirect_to(project_test_management_project_settings_path(project))
        setting = TestManagement::ProjectSetting.find_by!(project:)
        expect(setting.effective_navigation_layout).to eq("horizontal")
        expect(setting.options.keys).to eq(["navigation_layout"])
      end

      it "shows the settings form with navigation layout" do
        get project_test_management_project_settings_path(project)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-test-selector="tm-project-settings-form"')
        expect(response.body).to include('data-test-selector="tm-navigation-layout"')
        expect(response.body).not_to include("tm-enable-")
      end

      it "rejects a display prefix that is too long" do
        too_long = "x" * (TestManagement::ProjectSetting::DISPLAY_PREFIX_MAX_LENGTH + 1)

        patch project_test_management_project_settings_path(project),
              params: { project_setting: { display_prefix: too_long } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(TestManagement::ProjectSetting.find_by(project:)&.display_prefix).not_to eq(too_long)
      end
    end

    context "without manage_test_management" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_test_cases] })
      end

      before { login_as(user) }

      it "forbids update" do
        patch project_test_management_project_settings_path(project),
              params: { project_setting: { display_prefix: "XX" } }

        expect(response).to have_http_status(:forbidden)
        expect(TestManagement::ProjectSetting.find_by(project:)&.display_prefix).not_to eq("XX")
      end
    end
  end
end

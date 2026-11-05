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
require "rack/test"

RSpec.describe "APIv3 test management project settings" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_management] }) }
  shared_let(:outsider) { create(:user) }

  let(:current) { manager }
  let(:path) { api_v3_paths.project_test_management_settings(project.id) }

  before { login_as(current) }

  def json = JSON.parse(last_response.body)

  def patch_json(body)
    patch path, body.to_json, { "CONTENT_TYPE" => "application/json" }
  end

  it "renders the defaults" do
    get path

    expect(last_response).to have_http_status(200)
    expect(json).to include("_type" => "TestManagementProjectSettings", "folderTreeLayout" => "split_pane",
                            "enableCi" => true, "enableTestAssistant" => true)
    expect(json["displayPrefix"]).to be_present
  end

  it "is readable with view_test_cases" do
    login_as(viewer)

    get path

    expect(last_response).to have_http_status(200)
  end

  it "updates the toggles, layout and prefix" do
    patch_json(enableCi: false, folderTreeLayout: "sidebar", displayPrefix: "QA")

    expect(last_response).to have_http_status(200)
    expect(json).to include("enableCi" => false, "folderTreeLayout" => "sidebar", "displayPrefix" => "QA")
    expect(TestManagement::ProjectSetting.enabled?(project, :ci)).to be(false)
  end

  it "answers 422 for an unknown layout" do
    patch_json(folderTreeLayout: "grid")

    expect(last_response).to have_http_status(422)
  end

  it "is forbidden for viewers and not found for outsiders" do
    login_as(viewer)
    patch_json(enableCi: false)
    expect(last_response).to have_http_status(403)
    expect(TestManagement::ProjectSetting.enabled?(project, :ci)).to be(true)

    login_as(outsider)
    get path
    expect(last_response).to have_http_status(404)
  end
end

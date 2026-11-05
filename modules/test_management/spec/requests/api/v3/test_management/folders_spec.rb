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

RSpec.describe "APIv3 test management folders" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_suites] }) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }
  shared_let(:outsider) { create(:user) }

  let(:current) { manager }
  let(:collection_path) { api_v3_paths.project_test_management_folders(project.id) }

  before { login_as(current) }

  def json = JSON.parse(last_response.body)

  def send_json(verb, path, body = {})
    public_send(verb, path, body.to_json, { "CONTENT_TYPE" => "application/json" })
  end

  describe "GET collection" do
    it "lists the folders of the project" do
      root = create(:tm_suite, project:)
      child = create(:tm_suite, project:, parent: root)
      create(:tm_suite)

      get collection_path

      expect(last_response).to have_http_status(200)
      expect(json["_embedded"]["elements"].pluck("id")).to contain_exactly(root.id, child.id)
    end

    it "is not found for outsiders" do
      login_as(outsider)

      get collection_path

      expect(last_response).to have_http_status(404)
    end
  end

  describe "POST collection" do
    it "creates a root folder and a subfolder (201)" do
      send_json(:post, collection_path, { name: "Accounts" })
      expect(last_response).to have_http_status(201)
      expect(json).to include("_type" => "TestManagementFolder", "name" => "Accounts")
      expect(json["_links"]).not_to include("parent")
      parent_id = json["id"]

      send_json(:post, collection_path, { name: "Sign in", parentId: parent_id })
      expect(last_response).to have_http_status(201)
      expect(json.dig("_links", "parent", "href")).to eq(api_v3_paths.test_management_folder(parent_id))
    end

    it "answers 422 for a blank or duplicate name and a foreign parent" do
      create(:tm_suite, project:, name: "Accounts")

      send_json(:post, collection_path, { name: "" })
      expect(last_response).to have_http_status(422)

      send_json(:post, collection_path, { name: "Accounts" })
      expect(last_response).to have_http_status(422)

      send_json(:post, collection_path, { name: "Child", parentId: create(:tm_suite).id })
      expect(last_response).to have_http_status(422)
    end

    it "is forbidden without manage_test_suites" do
      login_as(viewer)

      send_json(:post, collection_path, { name: "Nope" })

      expect(last_response).to have_http_status(403)
    end
  end

  describe "single folder" do
    let!(:folder) { create(:tm_suite, project:, name: "Old") }
    let(:path) { api_v3_paths.test_management_folder(folder.id) }

    it "renders, renames and deletes the folder" do
      get path
      expect(last_response).to have_http_status(200)
      expect(json).to include("name" => "Old")

      send_json(:patch, path, { name: "New" })
      expect(last_response).to have_http_status(200)
      expect(folder.reload.name).to eq("New")

      send_json(:delete, path)
      expect(last_response).to have_http_status(204)
      expect(TestManagement::Suite.exists?(folder.id)).to be(false)
    end

    it "unfiles the cases of a deleted folder" do
      test_case = create(:tm_test_case, project:, suite: folder)

      send_json(:delete, path)

      expect(test_case.reload.suite_id).to be_nil
    end

    it "is forbidden for viewers and not found for outsiders" do
      login_as(viewer)
      send_json(:patch, path, { name: "X" })
      expect(last_response).to have_http_status(403)
      send_json(:delete, path)
      expect(last_response).to have_http_status(403)

      login_as(outsider)
      get path
      expect(last_response).to have_http_status(404)
      expect(folder.reload.name).to eq("Old")
    end
  end
end

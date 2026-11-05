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

RSpec.describe "APIv3 test management CI connection writes" do
  include Rack::Test::Methods

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:ci_admin) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_ci] }) }
  shared_let(:uploader) { create(:user, member_with_permissions: { project => %i[view_test_cases upload_test_results] }) }
  shared_let(:outsider) { create(:user) }

  let(:current) { ci_admin }
  let(:collection_path) { "/api/v3/projects/#{project.id}/test_management/ci_connections" }

  before { login_as(current) }

  def json = JSON.parse(last_response.body)

  def send_json(verb, path, body = {})
    public_send(verb, path, body.to_json, { "CONTENT_TYPE" => "application/json" })
  end

  def expect_error(status, identifier)
    expect(last_response).to have_http_status(status)
    expect(json["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:#{identifier}")
  end

  describe "POST /projects/:id/test_management/ci_connections" do
    let(:body) do
      { name: "Shop", provider: "github", repository: "my-org/shop", ingestMode: "new_run", token: "ghp_secret_value",
        workflow: "e2e.yml", ref: "main" }
    end

    it "creates the connection (201) and never renders the secrets" do
      send_json(:post, collection_path, body)

      expect(last_response).to have_http_status(:created)
      expect(json).to include("_type" => "TestManagementCiConnection", "name" => "Shop", "repository" => "my-org/shop",
                              "workflow" => "e2e.yml", "ref" => "main", "tokenSet" => true, "triggerReady" => true)
      expect(last_response.body).not_to include("ghp_secret_value")

      connection = TestManagement::CiConnection.find(json["id"])
      expect(connection).to have_attributes(decrypted_token: "ghp_secret_value", created_by_id: ci_admin.id)
    end

    it "rejects a duplicate repository, unknown providers and wrong types (422)" do
      send_json(:post, collection_path, body)
      expect(last_response).to have_http_status(:created)

      send_json(:post, collection_path, body.merge(name: "Again", repository: "My-Org/Shop"))
      expect_error(422, "UnprocessableContent")

      send_json(:post, collection_path, body.merge(name: "Other", repository: "my-org/other", provider: "gitlab"))
      expect(last_response).to have_http_status(422)

      send_json(:post, collection_path, body.merge(name: "Typed", repository: "my-org/typed", active: "yes"))
      expect(last_response).to have_http_status(422)
      expect(TestManagement::CiConnection.where(project_id: project.id).count).to eq(1)
    end

    it "is forbidden without manage_test_ci (403) and not found for outsiders (404)" do
      login_as(uploader)
      send_json(:post, collection_path, body)
      expect_error(403, "MissingPermission")

      login_as(outsider)
      send_json(:post, collection_path, body)
      expect(last_response).to have_http_status(:not_found)
    end
  end

  describe "PATCH / DELETE /test_management/ci_connections/:id" do
    let!(:connection) { create(:tm_ci_connection, :github_trigger, project:, name: "Shop") }
    let(:path) { "/api/v3/test_management/ci_connections/#{connection.id}" }

    it "updates (200); a blank token keeps the stored one, removeToken clears it" do
      send_json(:patch, path, { name: "Shop web", token: "", workflow: "web.yml" })

      expect(last_response).to have_http_status(:ok)
      expect(json).to include("name" => "Shop web", "workflow" => "web.yml", "tokenSet" => true)
      expect(last_response.body).not_to include("ghp_trigger_secret")
      expect(connection.reload.decrypted_token).to eq("ghp_trigger_secret")

      send_json(:patch, path, { removeToken: true })
      expect(last_response).to have_http_status(:ok)
      expect(connection.reload).not_to be_token_set
    end

    it "returns 422 for invalid values" do
      send_json(:patch, path, { workflow: "not-a-workflow.txt" })

      expect(last_response).to have_http_status(422)
    end

    it "deletes (204)" do
      send_json(:delete, path)

      expect(last_response).to have_http_status(:no_content)
      expect(last_response.body).to be_empty
      expect(TestManagement::CiConnection).not_to exist(connection.id)
    end

    it "is forbidden for uploaders (403) and not found for outsiders (404)" do
      login_as(uploader)
      send_json(:patch, path, { name: "X" })
      expect_error(403, "MissingPermission")
      send_json(:delete, path)
      expect_error(403, "MissingPermission")

      login_as(outsider)
      send_json(:delete, path)
      expect(last_response).to have_http_status(:not_found)
      expect(TestManagement::CiConnection).to exist(connection.id)
    end
  end
end

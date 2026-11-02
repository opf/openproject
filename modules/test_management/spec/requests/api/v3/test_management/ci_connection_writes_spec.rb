# frozen_string_literal: true

require "spec_helper"
require "rack/test"

# 0016: create / update / delete CI connections through APIv3 (manage_test_ci); secrets are write-only.
RSpec.describe "APIv3 test management CI connection writes" do
  include Rack::Test::Methods

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management repository]) }
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
      { name: "Shop internal", provider: "gitlab", baseUrl: "https://git.example.com/gitlab/", repository: "qa/web/shop",
        ingestMode: "new_run", token: "glpat-secret-value", triggerToken: "glptt-secret-value", ref: "main",
        referenceName: "shop", e2eTests: "always" }
    end

    it "creates the connection (201) and never renders the secrets" do
      send_json(:post, collection_path, body)

      expect(last_response).to have_http_status(:created)
      expect(json).to include("_type" => "TestManagementCiConnection", "name" => "Shop internal",
                              "serverUrl" => "https://git.example.com/gitlab", "referenceName" => "shop",
                              "referenceQualifier" => "shop", "e2eTests" => "always", "tokenSet" => true)
      expect(last_response.body).not_to include("glpat-secret-value", "glptt-secret-value")

      connection = TestManagement::CiConnection.find(json["id"])
      expect(connection).to have_attributes(decrypted_token: "glpat-secret-value", trigger_ref: "main",
                                            created_by_id: ci_admin.id)
    end

    it "accepts the same repository on another server and rejects a duplicate (422)" do
      create(:tm_ci_connection, :gitlab, project:, repository: "qa/web/shop")
      send_json(:post, collection_path, body)
      expect(last_response).to have_http_status(:created)

      send_json(:post, collection_path, body.merge(name: "Again", baseUrl: "https://GIT.example.com/gitlab"))
      expect_error(422, "UnprocessableContent")
    end

    it "rejects http, invalid attributes and wrong types (422)" do
      send_json(:post, collection_path, body.merge(baseUrl: "http://git.example.com"))
      expect(last_response).to have_http_status(422)

      send_json(:post, collection_path, body.merge(e2eTests: "sometimes"))
      expect(last_response).to have_http_status(422)

      send_json(:post, collection_path, body.merge(active: "yes"))
      expect(last_response).to have_http_status(422)
      expect(TestManagement::CiConnection.where(project_id: project.id)).to be_empty
    end

    it "attaches a Repositories-module repository of the project" do
      repository = create(:repository_git, project:)
      send_json(:post, collection_path, body.merge(scmRepositoryId: repository.id))

      expect(last_response).to have_http_status(:created)
      expect(json["scmRepositoryId"]).to eq(repository.id)
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
    let!(:connection) { create(:tm_ci_connection, :self_hosted_gitlab, project:, name: "Shop") }
    let(:path) { "/api/v3/test_management/ci_connections/#{connection.id}" }

    it "updates (200); a blank token keeps the stored one, removeToken clears it" do
      send_json(:patch, path, { name: "Shop web", token: "", referenceName: "web" })

      expect(last_response).to have_http_status(:ok)
      expect(json).to include("name" => "Shop web", "referenceQualifier" => "web", "tokenSet" => true)
      expect(last_response.body).not_to include("glpat-selfhosted-secret", "glptt-selfhosted-secret")
      expect(connection.reload.decrypted_token).to eq("glpat-selfhosted-secret")

      send_json(:patch, path, { removeToken: true })
      expect(last_response).to have_http_status(:ok)
      expect(connection.reload).not_to be_token_set
    end

    it "returns 422 for invalid values" do
      send_json(:patch, path, { referenceName: "-bad name" })
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

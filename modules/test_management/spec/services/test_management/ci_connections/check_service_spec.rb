# frozen_string_literal: true

require "spec_helper"

# WebMock is only enabled for examples tagged :webmock (spec/support/webmock.rb); without it
# the stubs are ignored and the real network is used. :disable_ssrf_filter lets
# OpenProject.httpx reach the stubbed hosts.
RSpec.describe TestManagement::CiConnections::CheckService, :disable_ssrf_filter, :webmock do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:admin) { create(:user, member_with_permissions: { project => %i[manage_test_ci] }) }
  shared_let(:uploader) { create(:user, member_with_permissions: { project => %i[upload_test_results] }) }

  let(:connection) { create(:tm_ci_connection, project:, repository: "my-org/shop", token: "ghp_secret_token_value") }

  def check(user = admin) = described_class.new(user:, connection:).call

  it "reads the GitHub repository with the token and stores ok" do
    stub = stub_request(:get, "https://api.github.com/repos/my-org/shop")
             .with(headers: { "Authorization" => "Bearer ghp_secret_token_value" })
             .to_return(status: 200, body: "{}")

    expect(check).to be_success
    expect(stub).to have_been_requested
    expect(connection.reload).to have_attributes(check_status: "ok", check_message: "HTTP 200")
    expect(connection.checked_at).to be_present
  end

  it "maps 401 and 404" do
    stub_request(:get, "https://api.github.com/repos/my-org/shop").to_return(status: 401)
    check
    expect(connection.reload.check_status).to eq("unauthorized")

    stub_request(:get, "https://api.github.com/repos/my-org/shop").to_return(status: 404)
    check
    expect(connection.reload.check_status).to eq("not_found")
  end

  it "uses the GitLab API of a self-managed instance with PRIVATE-TOKEN" do
    gitlab = create(:tm_ci_connection, :gitlab, project:, repository: "group/sub/app",
                                                base_url: "https://gitlab.example.com", token: "glpat-secret")
    stub = stub_request(:get, "https://gitlab.example.com/api/v4/projects/group%2Fsub%2Fapp")
             .with(headers: { "PRIVATE-TOKEN" => "glpat-secret" }).to_return(status: 200, body: "{}")
    # Since 0015 an ok check also reads the server version (best effort).
    metadata = stub_request(:get, "https://gitlab.example.com/api/v4/metadata")
                 .with(headers: { "PRIVATE-TOKEN" => "glpat-secret" })
                 .to_return(status: 200, body: { version: "17.5.1-ee" }.to_json)

    expect(described_class.new(user: admin, connection: gitlab).call).to be_success
    expect(stub).to have_been_requested
    expect(metadata).to have_been_requested
    expect(gitlab.reload).to have_attributes(check_status: "ok", server_version: "17.5.1-ee")
  end

  it "uses /api/v3 for GitHub Enterprise" do
    ghes = create(:tm_ci_connection, project:, repository: "team/app", base_url: "https://ghe.example.com", token: "t")

    expect(described_class.new(user: admin, connection: ghes).url).to eq("https://ghe.example.com/api/v3/repos/team/app")
  end

  it "records network errors without leaking the token" do
    stub_request(:get, "https://api.github.com/repos/my-org/shop").to_timeout

    check
    expect(connection.reload.check_status).to eq("error")
    expect(connection.check_message).not_to include("ghp_secret_token_value")
  end

  it "needs manage_test_ci and a stored token" do
    expect(check(uploader)).to be_failure

    connection.update!(remove_token: "1")
    expect(check).to be_failure
    expect(connection.check_status).to be_nil
  end

  describe "Run in CI providers (0011)" do
    it "Jenkins: reads the job with HTTP Basic user:API token" do
      jenkins = create(:tm_ci_connection, :jenkins, project:)
      stub = stub_request(:get, "https://jenkins.example.com/job/qa/job/e2e/api/json")
               .with(basic_auth: %w[op-bot jenkins-api-secret]).to_return(status: 200, body: "{}")

      expect(described_class.new(user: admin, connection: jenkins).call).to be_success
      expect(stub).to have_been_requested
      expect(jenkins.reload.check_status).to eq("ok")
    end

    it "Jenkins: needs the user name" do
      jenkins = create(:tm_ci_connection, :jenkins, project:, ci_username: "")
      call = described_class.new(user: admin, connection: jenkins).call
      expect(call).to be_failure
      expect(call.errors.details[:base]).to include(error: :tm_ci_check_needs_username)
    end

    it "Gitea, Forgejo and Codeberg: /api/v1/repos with 'token'" do
      {
        gitea: "https://gitea.example.com/api/v1/repos/my-org/shop",
        forgejo: "https://forgejo.example.com/api/v1/repos/my-org/shop",
        codeberg: "https://codeberg.org/api/v1/repos/my-org/shop"
      }.each do |trait, url|
        record = create(:tm_ci_connection, trait, project:)
        stub = stub_request(:get, url).with(headers: { "Authorization" => "token #{trait}-secret" })
                 .to_return(status: 404)
        described_class.new(user: admin, connection: record).call
        expect(stub).to have_been_requested
        expect(record.reload.check_status).to eq("not_found")
      end
    end

    it "Woodpecker: /api/repos/:id with a Bearer token" do
      woodpecker = create(:tm_ci_connection, :woodpecker, project:)
      stub = stub_request(:get, "https://ci.example.com/api/repos/42")
               .with(headers: { "Authorization" => "Bearer woodpecker-secret" }).to_return(status: 401)

      described_class.new(user: admin, connection: woodpecker).call
      expect(stub).to have_been_requested
      expect(woodpecker.reload.check_status).to eq("unauthorized")
    end
  end
end

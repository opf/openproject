# frozen_string_literal: true

require "spec_helper"
require_relative "../../../support/test_management_certificates"

# Self-hosted servers (0015): "Check connection" on a sub-path, server version, SSRF and TLS
# messages, the connection's CA in the HTTP session. WebMock only; no real server is called.
RSpec.describe TestManagement::CiConnections::CheckService, "self-hosted servers", :disable_ssrf_filter, :webmock do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:admin) { create(:user, member_with_permissions: { project => %i[manage_test_ci] }) }

  let(:connection) { create(:tm_ci_connection, :self_hosted_gitlab, project:) }
  let(:api) { "https://git.example.com/gitlab/api/v4" }

  def check(conn = connection) = described_class.new(user: admin, connection: conn).call

  it "calls the API below the relative URL root and stores the version" do
    project_stub = stub_request(:get, "#{api}/projects/qa%2Fweb%2Fshop")
                     .with(headers: { "PRIVATE-TOKEN" => "glpat-selfhosted-secret" }).to_return(status: 200, body: "{}")
    stub_request(:get, "#{api}/metadata")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { version: "17.5.1-ee", revision: "abc" }.to_json)

    expect(check).to be_success
    expect(project_stub).to have_been_requested
    expect(connection.reload).to have_attributes(check_status: "ok", server_version: "17.5.1-ee")
    expect(connection.check_message).to include("17.5.1-ee")
  end

  it "falls back to /version and flags GitLab older than 15.7" do
    stub_request(:get, "#{api}/projects/qa%2Fweb%2Fshop").to_return(status: 200, body: "{}")
    stub_request(:get, "#{api}/metadata").to_return(status: 404)
    stub_request(:get, "#{api}/version")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { version: "15.4.2" }.to_json)

    check
    expect(connection.reload.server_version).to eq("15.4.2")
    expect(connection.check_message).to include("15.7")
  end

  it "keeps the check ok when the version cannot be read" do
    stub_request(:get, "#{api}/projects/qa%2Fweb%2Fshop").to_return(status: 200, body: "{}")
    stub_request(:get, "#{api}/metadata").to_return(status: 403)
    stub_request(:get, "#{api}/version").to_return(status: 403)

    check
    expect(connection.reload).to have_attributes(check_status: "ok", server_version: nil)
  end

  it "reads Gitea / Forgejo versions on a sub-path and the Jenkins header" do
    forgejo = create(:tm_ci_connection, :forgejo, project:, base_url: "https://example.com/forgejo")
    stub_request(:get, "https://example.com/forgejo/api/v1/repos/my-org/shop").to_return(status: 200, body: "{}")
    stub_request(:get, "https://example.com/forgejo/api/v1/version")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { version: "11.0.3+gitea-1.22.0" }.to_json)
    check(forgejo)
    expect(forgejo.reload.server_version).to eq("11.0.3+gitea-1.22.0")

    jenkins = create(:tm_ci_connection, :jenkins, project:, base_url: "https://example.com/jenkins")
    stub_request(:get, %r{\Ahttps://example\.com/jenkins/job/qa/job/e2e/}).to_return(status: 200, body: "{}",
                                                                                     headers: { "X-Jenkins" => "2.462.3" })
    check(jenkins)
    expect(jenkins.reload).to have_attributes(check_status: "ok", server_version: "2.462.3")
  end

  it "explains a blocked private address with the allowlist variable and the addresses" do
    allow(Resolv).to receive(:getaddresses).with("git.example.com").and_return(["10.20.0.15"])
    stub_request(:get, "#{api}/projects/qa%2Fweb%2Fshop").to_raise(OpenProject::ServerSideRequestForgeryError)

    check
    expect(connection.reload.check_status).to eq("error")
    expect(connection.check_message).to include("git.example.com", "OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST", "10.20.0.15")
    expect(connection.check_message).not_to include("glpat-selfhosted-secret")
  end

  it "explains an untrusted certificate" do
    stub_request(:get, "#{api}/projects/qa%2Fweb%2Fshop").to_raise(OpenSSL::SSL::SSLError.new("certificate verify failed"))

    check
    expect(connection.reload.check_message).to include("git.example.com", "certificate verify failed", "CA certificate")
  end

  it "never calls an inbound-only server" do
    connection.update_columns(inbound_only: true)

    expect(check).not_to be_success
    expect(WebMock).not_to have_requested(:any, %r{\Ahttps?://git\.example\.com(?::|[/:?#]|\z)})
  end

  describe TestManagement::CiConnections::Http do
    it "adds the connection's CA to the system store of the session" do
      ca = TestManagementCertificates.ca
      connection.update_columns(ca_certificate: ca.to_pem)

      session = described_class.session(connection, timeout: 5)
      store = session.instance_variable_get(:@options).ssl[:cert_store]

      expect(store).to be_a(OpenSSL::X509::Store)
      expect(store.verify(TestManagementCertificates.server(ca))).to be(true)
    end

    it "uses OpenProject's default TLS settings without a CA (never verify_mode none)" do
      session = described_class.session(connection, timeout: 5)
      ssl = session.instance_variable_get(:@options).ssl

      expect(ssl[:cert_store]).to be_nil
      expect(ssl[:verify_mode]).not_to eq(OpenSSL::SSL::VERIFY_NONE)
    end
  end
end

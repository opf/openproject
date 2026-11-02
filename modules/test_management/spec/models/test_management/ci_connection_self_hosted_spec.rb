# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/test_management_certificates"

# Self-hosted servers (0015): sub-path base URLs, CA certificate, inbound only, server matching.
RSpec.describe TestManagement::CiConnection, "self-hosted servers" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }

  let(:ca) { TestManagementCertificates.ca }

  describe "base URL with a sub-path" do
    it "keeps the relative URL root in the repository and API URLs" do
      connection = build(:tm_ci_connection, :self_hosted_gitlab, project:, base_url: "https://git.example.com/gitlab/")

      expect(connection).to be_valid
      expect(connection.effective_base_url).to eq("https://git.example.com/gitlab")
      expect(connection.repository_url).to eq("https://git.example.com/gitlab/qa/web/shop")
    end

    it "rejects query strings, fragments, credentials and plain HTTP" do
      %w[https://git.example.com/gitlab?x=1 https://git.example.com/gitlab#top
         https://user:pw@git.example.com/gitlab http://git.example.com/gitlab].each do |url|
        connection = build(:tm_ci_connection, :self_hosted_gitlab, project:, base_url: url)
        expect(connection).not_to be_valid, url
        expect(connection.errors.details[:base_url]).to include(error: :invalid)
      end
    end
  end

  describe "#file_url" do
    it "builds file links below the sub-path per forge" do
      gitlab = build(:tm_ci_connection, :self_hosted_gitlab, project:, trigger_ref: "main")
      expect(gitlab.file_url("tests/login spec.ts", ref: "main"))
        .to eq("https://git.example.com/gitlab/qa/web/shop/-/blob/main/tests/login%20spec.ts")

      gitea = build(:tm_ci_connection, :gitea, project:, base_url: "https://example.com/git")
      sha = "a" * 40
      expect(gitea.file_url("./e2e/cart.spec.ts", ref: sha))
        .to eq("https://example.com/git/my-org/shop/src/commit/#{sha}/e2e/cart.spec.ts")
      expect(gitea.file_url("e2e/cart.spec.ts", ref: "dev")).to eq("https://example.com/git/my-org/shop/src/branch/dev/e2e/cart.spec.ts")
    end

    it "returns nil for CI-only providers, traversal and URLs" do
      expect(build(:tm_ci_connection, :jenkins, project:).file_url("a/b.rb")).to be_nil
      gitlab = build(:tm_ci_connection, :self_hosted_gitlab, project:)
      expect(gitlab.file_url("../secrets.yml")).to be_nil
      expect(gitlab.file_url("https://evil.example.com/x.rb")).to be_nil
    end
  end

  describe "CA certificate" do
    it "accepts a PEM bundle, ignores text around it and builds a store that trusts the CA" do
      connection = build(:tm_ci_connection, :self_hosted_gitlab, project:,
                                                                 ca_certificate: "subject=CN = Example\r\n#{ca.to_pem}")
      expect(connection).to be_valid
      connection.validate
      expect(connection.ca_certificate).not_to include("\r")

      store = connection.ca_cert_store
      expect(store).to be_a(OpenSSL::X509::Store)
      expect(store.verify(TestManagementCertificates.server(ca))).to be(true)
      expect(connection.ca_summary).to contain_exactly(hash_including(name: "Example Internal Root CA", expired: false))
    end

    it "has no own store without a CA (system store applies)" do
      expect(build(:tm_ci_connection, :self_hosted_gitlab, project:).ca_cert_store).to be_nil
    end

    it "rejects private keys, garbage, too many certificates and oversized input" do
      key_pem = TestManagementCertificates.key.to_pem
      {
        "#{ca.to_pem}#{key_pem}" => :private_key,
        "not a certificate" => :pem,
        "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----" => :pem,
        ca.to_pem * 11 => :pem,
        ("#" * 70_000) => :too_long
      }.each do |value, error|
        connection = build(:tm_ci_connection, :self_hosted_gitlab, project:, ca_certificate: value)
        expect(connection).not_to be_valid
        expect(connection.errors.details[:ca_certificate].pluck(:error)).to include(error)
      end
    end

    it "flags expired certificates in the summary" do
      old = TestManagementCertificates.ca("Old CA", not_after: 1.day.ago)
      connection = build(:tm_ci_connection, :self_hosted_gitlab, project:, ca_certificate: old.to_pem)
      expect(connection.ca_summary.first).to include(name: "Old CA", expired: true)
    end

    it "requires the tokens again when the CA changes" do
      connection = create(:tm_ci_connection, :self_hosted_gitlab, project:)
      connection.ca_certificate = ca.to_pem

      expect(connection).not_to be_valid
      expect(connection.errors.details[:token]).to include(error: :reenter_for_new_endpoint)
    end
  end

  describe "inbound only" do
    it "needs no trigger settings and is not outbound" do
      connection = build(:tm_ci_connection, :self_hosted_gitlab, :inbound_only, project:, trigger_token: nil, token: nil)

      expect(connection).to be_valid
      expect(connection).not_to be_outbound
      expect(connection.trigger_missing).to eq([])
    end
  end

  describe ".server_key / .detect" do
    let!(:self_hosted) { create(:tm_ci_connection, :self_hosted_gitlab, project:) }

    it "compares scheme, host, port and sub-path" do
      expect(self_hosted.same_server?("https://GIT.example.com/gitlab/")).to be(true)
      expect(self_hosted.same_server?("https://git.example.com:443/gitlab")).to be(true)
      expect(self_hosted.same_server?("https://git.example.com")).to be(false)
      expect(self_hosted.same_server?("https://gitlab.com")).to be(false)
      expect(described_class.server_key("not a url")).to be_nil
    end

    it "detects only connections on the CI's server" do
      expect(described_class.detect(project, "gitlab", "QA/web/shop")).to eq(self_hosted)
      expect(described_class.detect(project, "gitlab", "qa/web/shop", server_url: "https://git.example.com/gitlab"))
        .to eq(self_hosted)
      expect(described_class.detect(project, "gitlab", "qa/web/shop", server_url: "https://gitlab.com")).to be_nil
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

# ci.serverUrl (0015): uploads are matched to the connection on the CI's own server.
RSpec.describe TestManagement::Automation::ConnectionResolver, "server URL" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:self_hosted) { create(:tm_ci_connection, :self_hosted_gitlab, project:, name: "Internal") }

  def resolve(raw)
    warnings = []
    plan = described_class.new(project:, options: TestManagement::Automation::Options.new(raw), warnings:).call
    [plan.connection, warnings]
  end

  it "detects the connection when CI_SERVER_URL (with sub-path) matches" do
    connection, = resolve("ci" => { "provider" => "gitlab", "repository" => "qa/web/shop",
                                    "serverUrl" => "https://git.example.com/gitlab" })
    expect(connection).to eq(self_hosted)
  end

  it "does not file gitlab.com results under the self-hosted connection with the same path" do
    connection, = resolve("ci" => { "provider" => "gitlab", "repository" => "qa/web/shop", "serverUrl" => "https://gitlab.com" })
    expect(connection).to be_nil
  end

  it "keeps working without serverUrl (older upload scripts)" do
    connection, = resolve("ci" => { "provider" => "gitlab", "repository" => "qa/web/shop" })
    expect(connection).to eq(self_hosted)
  end

  it "warns when an explicit connection is on another server" do
    connection, warnings = resolve("connection" => "Internal",
                                   "ci" => { "provider" => "gitlab", "repository" => "qa/web/shop",
                                             "serverUrl" => "https://other.example.com" })
    expect(connection).to eq(self_hosted)
    expect(warnings).to include(hash_including("code" => "connection_server_mismatch", "serverUrl" => "https://other.example.com"))
  end
end

RSpec.describe TestManagement::Automation::SourceLink do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:suite) { create(:tm_suite, project:) }

  let(:test_case) do
    create(:tm_test_case, project:, suite:, automation_reference: "tests/login.spec.ts#rejects a wrong password")
  end

  it "extracts file paths only" do
    expect(described_class.file_path("tests/login.spec.ts#x")).to eq("tests/login.spec.ts")
    expect(described_class.file_path("./e2e/cart.cy.js")).to eq("e2e/cart.cy.js")
    expect(described_class.file_path("checkout.feature")).to eq("checkout.feature")
    expect(described_class.file_path("com.acme.LoginTest#testWrongPassword")).to be_nil
    expect(described_class.file_path("../etc/passwd")).to be_nil
    expect(described_class.file_path("/abs/path.rb")).to be_nil
    expect(described_class.file_path("javascript:alert(1)//x.js")).to be_nil
  end

  it "links to the commit of the latest run on its connection's server" do
    connection = create(:tm_ci_connection, :self_hosted_gitlab, project:)
    run = create(:tm_test_run, project:, connection:)
    run.add_cases!([test_case])
    sha = "0123456789abcdef0123456789abcdef01234567"
    TestManagement::TestRunIteration.create!(test_run: run, number: 1, source: "automation", connection:,
                                             ci_metadata: { "commitSha" => sha })

    link = described_class.new(test_case).call
    expect(link.url).to eq("https://git.example.com/gitlab/qa/web/shop/-/blob/#{sha}/tests/login.spec.ts")
    expect(link.ref).to eq(sha)
  end

  it "falls back to the project's only forge connection and its default branch" do
    create(:tm_ci_connection, :gitea, project:, base_url: "https://example.com/git", trigger_ref: "develop")
    create(:tm_ci_connection, :jenkins, project:)

    expect(described_class.new(test_case).call.url).to eq("https://example.com/git/my-org/shop/src/branch/develop/tests/login.spec.ts")
  end

  it "has no link without a forge connection or for non-file references" do
    expect(described_class.new(test_case).call).to be_nil

    create(:tm_ci_connection, :self_hosted_gitlab, project:)
    test_case.update_columns(automation_reference: "LoginTest#wrongPassword")
    expect(described_class.new(test_case.reload).call).to be_nil
  end
end

# frozen_string_literal: true

require "spec_helper"

# 0016: repo-qualified references in ingest, source links and "Run in CI".
RSpec.describe "Repo-qualified automation references" do # rubocop:disable RSpec/DescribeClass
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management repository]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases edit_test_cases view_test_runs
                                                           add_test_runs upload_test_results browse_repository] })
  end
  shared_let(:shop) { create(:tm_ci_connection, :gitlab, project:, name: "Shop", repository: "qa/web/shop") }
  shared_let(:api) { create(:tm_ci_connection, project:, name: "API", repository: "acme/api-service", reference_name: "api") }
  shared_let(:suite) { create(:tm_suite, project:) }

  let(:shop_case) do
    create(:tm_test_case, project:, suite:, automation_reference: "shop/e2e:e2e/checkout.spec.ts#checkout › pays")
  end
  let(:api_case) { create(:tm_test_case, project:, suite:, automation_reference: "api:e2e/checkout.spec.ts#checkout › pays") }
  let(:plain_case) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds") }
  let(:shop_ci) { { "provider" => "gitlab", "repository" => "qa/web/shop", "serverUrl" => "https://gitlab.com" } }

  before { User.current = user }

  def ingest(tests, options)
    TestManagement::Automation::IngestService.new(user:, project:).call(content: { tests: }.to_json, options:, files: [])
  end

  describe "ingest" do
    it "matches cases of its own repository and unqualified cases, never those of another repository" do
      shop_case && api_case && plain_case
      outcome = ingest([{ reference: "e2e/checkout.spec.ts#checkout › pays", status: "passed" },
                        { reference: "tests/cart.spec.ts#adds", status: "failed" }],
                       { "externalRef" => "q:1", "ci" => shop_ci })

      expect(outcome.run.run_cases.pluck(:test_case_id)).to contain_exactly(shop_case.id, plain_case.id)
    end

    it "writes back and auto-creates qualified references" do
      by_id = create(:tm_test_case, project:, suite:)
      ingest([{ caseId: by_id.id.to_s, reference: "src/unit/price.test.ts#rounds", status: "passed" },
              { reference: "e2e/new.spec.ts#new one", status: "passed" }],
             { "externalRef" => "q:2", "autoCreateCases" => true, "ci" => shop_ci })

      expect(by_id.reload.automation_reference).to eq("shop:src/unit/price.test.ts#rounds")
      expect(project.tm_test_cases.where(automation_reference: "shop/e2e:e2e/new.spec.ts#new one")).to exist
    end

    it "uses testType for the e2e suffix" do
      by_id = create(:tm_test_case, project:, suite:)
      ingest([{ caseId: by_id.id.to_s, reference: "tests/x.ts#y", status: "passed" }],
             { "externalRef" => "q:3", "connection" => "API", "testType" => "e2e" })

      expect(by_id.reload.automation_reference).to eq("api/e2e:tests/x.ts#y")
    end

    it "keeps references unqualified when no repository is known" do
      other = create(:project, enabled_module_names: %i[test_management])
      uploader = create(:user,
                        member_with_permissions: { other => %i[view_test_cases edit_test_cases add_test_runs
                                                               upload_test_results] })
      by_id = create(:tm_test_case, project: other)
      TestManagement::Automation::IngestService.new(user: uploader, project: other)
        .call(content: { tests: [{ caseId: by_id.id.to_s, reference: "tests/x.ts#y", status: "passed" }] }.to_json,
              options: { "externalRef" => "q:4" }, files: [])

      expect(by_id.reload.automation_reference).to eq("tests/x.ts#y")
    end

    it "warns when the repository exists on two servers and no serverUrl is sent" do
      create(:tm_ci_connection, :gitlab, project:, name: "Shop internal", repository: "qa/web/shop",
                                         base_url: "https://git.example.com/gitlab")
      warnings = []
      plan = TestManagement::Automation::ConnectionResolver
               .new(project:, options: TestManagement::Automation::Options.new("ci" => shop_ci.except("serverUrl")), warnings:).call

      expect(plan.connection).to eq(shop)
      expect(warnings).to include(hash_including("code" => "connection_ambiguous", "others" => ["Shop internal"]))
    end
  end

  describe TestManagement::Automation::SourceLink do
    it "links a qualified reference via the named connection only" do
      link = described_class.new(api_case).call
      expect(link.connection).to eq(api)
      expect(link.url).to start_with("https://github.com/acme/api-service/blob/")
    end

    it "falls back to the repository browser of an attached Repositories-module repository" do
      repository = create(:repository_git, project:)
      create(:tm_ci_connection, :jenkins, project:, name: "Legacy", reference_name: "legacy", scm_repository: repository)
      legacy = create(:tm_test_case, project:, suite:, automation_reference: "legacy:tests/old.spec.ts#x")

      expect(described_class.new(legacy).call.url)
        .to eq("#{Setting.protocol}://#{Setting.host_name}/projects/#{project.identifier}/repository/entry/tests/old.spec.ts")
    end
  end

  describe TestManagement::CiTriggers::Request do
    it "runs only the connection's own and unqualified cases and strips the qualifier from grep" do
      own = described_class.new(project:, connection: api, test_case: api_case)
      expect(own.automated_cases.pluck(:id)).to eq([api_case.id])
      expect(own.grep).to eq(Regexp.escape("checkout › pays"))

      expect(described_class.new(project:, connection: api, test_case: shop_case).automated_cases).to be_empty
      expect(described_class.new(project:, connection: api, test_case: plain_case).automated_cases.count).to eq(1)
    end
  end
end

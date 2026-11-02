# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::IngestService do
  include FileHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs upload_test_results add_test_cases edit_test_cases]
           })
  end
  shared_let(:login_case) do
    create(:tm_test_case, project:, title: "Sign in",
                          automation_reference: "login.spec.ts#Login › signs in with valid credentials")
  end
  shared_let(:wrong_case) { create(:tm_test_case, project:, title: "Wrong password") }

  let(:service) { described_class.new(user:, project:) }
  let(:report) do
    File.read(File.expand_path("../../../fixtures/files/test_management/playwright-report.json", __dir__))
        .gsub("__CASE_ID__", wrong_case.id.to_s)
  end

  def ingest(content = report, options = {}, files = [], as: user)
    described_class.new(user: as, project:).call(content:, options:, files:)
  end

  def error_code
    yield
    nil
  rescue TestManagement::Automation::Error => e
    e.code
  end

  def native(tests)
    { tests: }.to_json
  end

  describe "a first upload" do
    subject(:outcome) { ingest(report, { "ci" => { "workflow" => "e2e", "runNumber" => "42", "branch" => "main" } }) }

    it "creates an automation run named after the CI metadata" do
      expect(outcome).to be_created_run
      expect(outcome.run).to have_attributes(source: "automation", state: "in_progress", name: "e2e #42 · main")
    end

    it "writes the worst status per case and keeps unmatched tests" do
      run = outcome.run
      statuses = run.run_cases.to_h { |rc| [rc.test_case_id, rc.status] }

      expect(statuses).to eq(login_case.id => "failed", wrong_case.id => "passed")
      expect(outcome.import).to have_attributes(state: "done", parsed_count: 5, matched_count: 3, unmatched_count: 2)
      expect(outcome.import.unmatched_list.pluck("reason").uniq).to eq(["no_matching_case"])
    end

    it "writes the reference back to a case matched by its tm_case annotation" do
      outcome

      expect(wrong_case.reload.automation_reference).to eq("login.spec.ts#Login › rejects a wrong password @TC-WRONG")
      expect(wrong_case).to be_automated
    end
  end

  it "treats the same payload as a replay" do
    first = ingest

    second = ingest(report, { "runId" => first.run.id })

    expect(second).to be_replay
    expect(second.import).to eq(first.import)
    expect(first.run.automation_imports.count).to eq(1)
  end

  it "lets shards with the same externalRef report into one run" do
    shard1 = ingest(native([{ reference: login_case.automation_reference, status: "passed" }]), { "externalRef" => "ci:1" })
    shard2 = ingest(native([{ caseId: wrong_case.id, status: "failed" }]), { "externalRef" => "ci:1" })

    expect(shard1).to be_created_run
    expect(shard2).not_to be_created_run
    expect(shard2.run).to eq(shard1.run)
    expect(shard2.run.run_cases.count).to eq(2)
  end

  it "completes the run for closeRun and refuses later uploads with :conflict" do
    outcome = ingest(report, { "externalRef" => "ci:2", "closeRun" => true })

    expect(outcome.run.reload).to have_attributes(state: "completed", completion_source: "automation")
    expect(error_code { ingest(native([{ caseId: wrong_case.id, status: "passed" }]), { "externalRef" => "ci:2" }) })
      .to eq(:conflict)
    expect(error_code { ingest(native([{ caseId: wrong_case.id, status: "passed" }]), { "runId" => outcome.run.id }) })
      .to eq(:conflict)
  end

  it "answers :not_found for a run of another project" do
    other_run = create(:tm_test_run)

    expect(error_code { ingest(report, { "runId" => other_run.id }) }).to eq(:not_found)
  end

  it "answers :forbidden without the upload permission" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] })

    expect(error_code { ingest(report, {}, [], as: viewer) }).to eq(:forbidden)
  end

  it "answers :payload_too_large for an oversized report" do
    stub_const("#{described_class}::MAX_BYTES", 10)

    expect(error_code { ingest }).to eq(:payload_too_large)
  end

  it "does not create cases for unmatched tests by default" do
    before_count = project.tm_test_cases.count
    outcome = ingest(report)

    expect(outcome.import.created_cases_count).to eq(0)
    expect(outcome.import.unmatched_count).to be_positive
    expect(project.tm_test_cases.count).to eq(before_count)
  end

  it "creates cases for unmatched tests with autoCreateCases" do
    outcome = ingest(report, { "autoCreateCases" => true })

    expect(outcome.import.created_cases_count).to eq(2)
    expect(outcome.import.unmatched_count).to eq(0)
    expect(project.tm_test_cases.where(automation_reference: "reports.spec.ts#exports a monthly report")).to exist
  end

  it "maps skipped tests as configured and leaves them out of the pass rate" do
    skipped_case = create(:tm_test_case, project:, automation_reference: "x#skip")
    outcome = ingest(native([{ caseId: wrong_case.id, status: "passed" },
                             { reference: "x#skip", status: "skipped" }]))
    counts = outcome.run.status_counts

    expect(outcome.run.run_cases.find_by(test_case: skipped_case).status).to eq("skipped")
    expect(TestManagement::TestRun.pass_rate(counts)).to eq(100)
  end

  describe "attachments" do
    let(:report) do
      native([{ reference: "a.spec.ts#one", status: "failed", attachments: [{ path: "/ci/test-results/a-one/test-failed-1.png" }] },
              { reference: "b.spec.ts#two", status: "failed",
                attachments: [{ path: "/ci/test-results/b-two/test-failed-1.png" }] }])
    end
    let!(:case_a) { create(:tm_test_case, project:, automation_reference: "a.spec.ts#one") }
    let!(:case_b) { create(:tm_test_case, project:, automation_reference: "b.spec.ts#two") }
    let(:files) do
      [mock_uploaded_file(name: "test-failed-1.png", content: "from b"),
       mock_uploaded_file(name: "test-failed-1.png", content: "from a"),
       mock_uploaded_file(name: "playwright-report.zip", content: "zip")]
    end

    it "matches equally named files by attachmentPaths and puts the rest on the run" do
      outcome = ingest(report, { "attachmentPaths" => %w[b-two/test-failed-1.png a-one/test-failed-1.png report.zip] }, files)
      run = outcome.run
      content_of = ->(test_case) { run.run_cases.find_by(test_case:).attachments.map { |a| a.diskfile.read } }

      expect(content_of.call(case_a)).to eq(["from a"])
      expect(content_of.call(case_b)).to eq(["from b"])
      expect(run.attachments.map(&:filename)).to eq(["playwright-report.zip"])
      expect(outcome.import.attachments_count).to eq(3)
    end

    it "falls back to the file name without paths" do
      outcome = ingest(report, {}, files.first(1))

      expect(outcome.run.run_cases.find_by(test_case: case_a).attachments.size).to eq(1)
      expect(outcome.run.attachments).to be_empty
    end
  end
end

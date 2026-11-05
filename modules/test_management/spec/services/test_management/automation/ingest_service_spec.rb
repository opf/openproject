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

RSpec.describe TestManagement::Automation::IngestService do
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

  def ingest(content = report, options = {}, acting: user)
    described_class.new(user: acting, project:).call(content:, options:)
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

      expect(statuses).to eq(login_case.id => "failed")
      expect(outcome.import).to have_attributes(state: "done", parsed_count: 5, matched_count: 2, unmatched_count: 3)
      expect(outcome.import.unmatched_list.pluck("reason").uniq).to eq(["no_matching_case"])
    end

    it "writes the reference back to a case matched by its ID" do
      ingest(native([{ caseId: wrong_case.id, reference: "login.spec.ts#wrong password", status: "passed" }]))

      expect(wrong_case.reload.automation_reference).to eq("login.spec.ts#wrong password")
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

    expect(error_code { ingest(report, {}, acting: viewer) }).to eq(:forbidden)
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

  it "creates cases for unmatched tests in a folder named after the file with createMissing" do
    outcome = ingest(report, { "createMissing" => true })
    created = project.tm_test_cases.find_by(automation_reference: "reports.spec.ts#exports a monthly report")

    expect(outcome.import.created_cases_count).to eq(3)
    expect(outcome.import.unmatched_count).to eq(0)
    expect(created).to have_attributes(automated: true)
    expect(created.suite.name).to eq("reports.spec.ts")
  end

  it "maps skipped tests as configured and leaves them out of the pass rate" do
    skipped_case = create(:tm_test_case, project:, automation_reference: "x#skip")
    outcome = ingest(native([{ caseId: wrong_case.id, status: "passed" },
                             { reference: "x#skip", status: "skipped" }]))
    counts = outcome.run.status_counts

    expect(outcome.run.run_cases.find_by(test_case: skipped_case).status).to eq("skipped")
    expect(TestManagement::TestRun.pass_rate(counts)).to eq(100)
  end
end

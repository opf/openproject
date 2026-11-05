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

RSpec.describe TestManagement::Automation::IngestService, "iterationId" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_test_runs upload_test_results] }) }
  shared_let(:case_a) { create(:tm_test_case, project:, title: "Checkout") }
  shared_let(:case_b) { create(:tm_test_case, project:, title: "Login") }

  let(:run) do
    create(:tm_test_run, project:, name: "Checkout · E2E", source: "automation").tap do |run|
      run.add_cases!([case_a, case_b])
    end
  end
  let(:starter) { TestManagement::TestRunIterations::Starter.new(run:, user:) }
  let!(:iteration) { starter.start!(name: "Run in CI · E2E", source: "automation") }

  def report = { tests: [{ caseId: case_a.id, status: "passed" }, { caseId: case_b.id, status: "failed" }] }.to_json

  def ingest(options)
    described_class.new(user:, project:).call(content: report, options: options.deep_stringify_keys.merge("format" => "native"))
  end

  def error_code
    yield
    nil
  rescue TestManagement::Automation::Error => e
    e.code
  end

  it "fills the pre-created iteration, also with mode new_iteration and an externalRef" do
    outcome = ingest(runId: run.id, iterationId: iteration.id, mode: "new_iteration", targetRun: "Smoke",
                     externalRef: "github:my-org/shop:1:1")

    expect(outcome).to have_attributes(created_run: false, created_iteration: false)
    expect(outcome.run).to eq(run)
    expect(outcome.iteration).to eq(iteration)
    expect(TestManagement::TestResult.where(iteration:).count).to eq(2)
    expect(run.iterations.count).to eq(1)
    expect(project.tm_test_runs.where(name: "Smoke")).to be_empty
  end

  it "finds the run from the iteration alone" do
    expect(ingest(iterationId: iteration.id).iteration).to eq(iteration)
  end

  it "rejects unknown, foreign, mismatched and outdated iterations" do
    expect(error_code { ingest(iterationId: 0) }).to eq(:not_found)

    foreign_run = create(:tm_test_run, project: other_project)
    foreign = TestManagement::TestRunIterations::Starter.new(run: foreign_run, user:).start!(source: "automation")
    expect(error_code { ingest(iterationId: foreign.id) }).to eq(:not_found)

    other_run = create(:tm_test_run, project:)
    expect(error_code { ingest(runId: other_run.id, iterationId: iteration.id) }).to eq(:unprocessable)

    starter.start!(name: "next", source: "manual")
    expect(error_code { ingest(iterationId: iteration.id) }).to eq(:conflict)
  end

  it "validates iterationId" do
    expect(error_code { ingest(iterationId: "abc") }).to eq(:unprocessable)
  end
end

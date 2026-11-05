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

RSpec.describe TestManagement::Automation::IngestService, "ingest modes and CI connections" do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_test_runs upload_test_results] }) }
  shared_let(:case_a) { create(:tm_test_case, project:, title: "Checkout") }
  shared_let(:case_b) { create(:tm_test_case, project:, title: "Login") }

  def report(status_a = "passed", status_b = "failed")
    { tests: [{ caseId: case_a.id, status: status_a }, { caseId: case_b.id, status: status_b }] }.to_json
  end

  def ingest(options = nil, content: report, **keyword_options)
    options = (options || {}).merge(keyword_options)
    described_class.new(user:, project:).call(content:, options: options.deep_stringify_keys.merge("format" => "native"))
  end

  def error_code
    yield
    nil
  rescue TestManagement::Automation::Error => e
    e.code
  end

  def github(build) = { provider: "github", repository: "my-org/shop", runNumber: build.to_s, branch: "main" }

  describe "new_run (default)" do
    it "creates iteration 1 in every new run" do
      outcome = ingest(externalRef: "ci:1")

      expect(outcome).to have_attributes(created_run: true, created_iteration: true, mode: "new_run")
      expect(outcome.iteration.number).to eq(1)
      expect(outcome.import.iteration).to eq(outcome.iteration)
      expect(TestManagement::TestResult.where(iteration: outcome.iteration).count).to eq(2)

      shard = ingest({ externalRef: "ci:1" }, content: { tests: [{ caseId: case_a.id, status: "failed" }] }.to_json)
      expect(shard).to have_attributes(created_run: false, created_iteration: false, replay: false)
      expect(shard.iteration).to eq(outcome.iteration)
    end

    it "gives a legacy run without iterations an iteration 1 that holds its earlier results" do
      run = create(:tm_test_run, :automation, :in_progress, project:, external_ref: "ci:legacy")
      run_case = create(:tm_test_run_case, test_run: run, test_case: case_a, status: "failed")
      old = create(:tm_test_result, run_case:, status: "failed")

      outcome = ingest(externalRef: "ci:legacy")

      expect(outcome.run).to eq(run)
      expect(outcome.iteration.number).to eq(1)
      expect(old.reload.iteration).to eq(outcome.iteration)
    end
  end

  describe "new_iteration" do
    it "creates the target run on first use, then adds one iteration per build" do
      first = ingest(mode: "new_iteration", targetRun: "Smoke", externalRef: "gh:1", ci: github(1))

      expect(first).to have_attributes(created_run: true, created_iteration: true, mode: "new_iteration")
      expect(first.run.name).to eq("Smoke")
      expect(first.run.external_ref).to be_nil
      expect(first.import.warnings.pluck("code")).to include("target_run_created")
      expect(first.iteration).to have_attributes(number: 1, external_ref: "gh:1", source: "automation")

      second = ingest({ mode: "new_iteration", targetRun: "smoke", externalRef: "gh:2", ci: github(2) },
                      content: report("failed", "failed"))

      expect(second).to have_attributes(created_run: false, created_iteration: true)
      expect(second.run).to eq(first.run)
      expect(second.iteration.number).to eq(2)
      expect(first.iteration.reload.status_counts).to include("passed" => 1, "failed" => 1)
      expect(second.iteration.status_counts).to include("failed" => 2)
      expect(second.run.reload.status_counts).to include("failed" => 2, "passed" => 0)
    end

    it "puts shards of one build into the same iteration and replays an identical upload" do
      first = ingest(mode: "new_iteration", targetRun: "Smoke", externalRef: "gh:7")
      shard = ingest({ mode: "new_iteration", targetRun: "Smoke", externalRef: "gh:7" },
                     content: { tests: [{ caseId: case_a.id, status: "failed" }] }.to_json)
      replay = ingest(mode: "new_iteration", targetRun: "Smoke", externalRef: "gh:7")

      expect(shard.iteration).to eq(first.iteration)
      expect(shard.created_iteration).to be(false)
      expect(replay.replay).to be(true)
      expect(first.run.iterations.count).to eq(1)
    end

    it "treats the same report from a new build as a new iteration, not a replay" do
      ingest(mode: "new_iteration", targetRun: "Regression", externalRef: "nightly:1")
      again = ingest(mode: "new_iteration", targetRun: "Regression", externalRef: "nightly:2")

      expect(again).to have_attributes(replay: false, created_iteration: true)
      expect(again.iteration.number).to eq(2)
    end

    it "uses runId when given and ignores completed runs with the target name" do
      create(:tm_test_run, :completed, project:, name: "Smoke")
      explicit = create(:tm_test_run, :in_progress, project:, name: "Release check")

      by_id = ingest(mode: "new_iteration", runId: explicit.id)
      by_name = ingest(mode: "new_iteration", targetRun: "Smoke", externalRef: "x:1")

      expect(by_id.run).to eq(explicit)
      expect(by_name.created_run).to be(true)
    end

    it "answers 422 without a target and for an invalid mode" do
      expect(error_code { ingest(mode: "new_iteration") }).to eq(:unprocessable)
      expect(error_code { ingest(mode: "sometimes") }).to eq(:unprocessable)
    end
  end

  describe "CI connections" do
    let!(:connection) do
      create(:tm_ci_connection, :new_iteration, project:, name: "Shop", repository: "my-org/shop", target_run_name: "Smoke")
    end

    it "detects the connection by provider and repository and applies its mode and target run" do
      outcome = ingest(externalRef: "gh:1", ci: github(1))

      expect(outcome.connection).to eq(connection)
      expect(outcome).to have_attributes(mode: "new_iteration")
      expect(outcome.run).to have_attributes(name: "Smoke", connection_id: connection.id)
      expect(outcome.iteration.connection).to eq(connection)
    end

    it "lets the request override the connection's mode" do
      outcome = ingest(mode: "new_run", externalRef: "gh:pr-1", ci: github(1))

      expect(outcome).to have_attributes(mode: "new_run", created_run: true, connection: connection)
      expect(outcome.run.external_ref).to eq("gh:pr-1")
    end

    it "accepts an explicit connection by name and warns about a repository mismatch" do
      outcome = ingest(connection: "shop", externalRef: "gh:1", ci: { provider: "github", repository: "my-org/other" })

      expect(outcome.connection).to eq(connection)
      expect(outcome.import.warnings.pluck("code")).to include("connection_repository_mismatch")
    end

    it "rejects an unknown or inactive explicit connection and ignores an inactive detected one" do
      expect(error_code { ingest(connection: "nope") }).to eq(:unprocessable)

      connection.update!(active: false)
      expect(error_code { ingest(connection: "Shop") }).to eq(:unprocessable)

      outcome = ingest(externalRef: "gh:9", ci: github(9))
      expect(outcome).to have_attributes(connection: nil, mode: "new_run")
      expect(outcome.import.warnings.pluck("code")).to include("connection_inactive")
    end
  end
end

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

RSpec.describe TestManagement::CiTriggers::TriggerService, :disable_ssrf_filter, :webmock do
  shared_let(:project) { create(:project, identifier: "shop-web", enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Checkout") }
  shared_let(:case_a) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item") }
  shared_let(:case_b) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#removes item") }
  shared_let(:manual) { create(:tm_test_case, project:, suite:) }

  let(:grep) { "adds\\ item|removes\\ item" }

  def trigger(connection, **params)
    described_class.new(user:).call({ project:, connection:, suite: }.merge(params))
  end

  def inputs_for(outcome)
    { "op_run_id" => outcome.run.id.to_s, "op_iteration_id" => outcome.iteration.id.to_s,
      "op_project" => "shop-web", "op_grep" => grep }
  end

  describe "new_run" do
    let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }

    it "pre-creates a run with all cases of the folder and iteration 1, then dispatches the GitHub workflow" do
      stub = stub_request(:post, "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches")
               .with(headers: { "Authorization" => "Bearer ghp_trigger_secret" })
               .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                          body: { workflow_run_id: 9876, html_url: "https://github.com/my-org/shop/actions/runs/9876" }.to_json)

      call = trigger(connection)
      expect(call).to be_success
      outcome = call.result
      expect(outcome).to be_triggered
      expect(outcome).to have_attributes(url: "https://github.com/my-org/shop/actions/runs/9876", external_id: "9876",
                                         ref: "main", grep:)

      run = outcome.run.reload
      expect(run).to have_attributes(source: "automation", state: "new", connection_id: connection.id,
                                     ci_trigger_status: "triggered",
                                     ci_trigger_url: "https://github.com/my-org/shop/actions/runs/9876")
      expect(run.name).to be_present
      expect(run.run_cases.pluck(:test_case_id)).to contain_exactly(case_a.id, case_b.id, manual.id)
      expect(outcome.iteration.reload).to have_attributes(number: 1, source: "automation", connection_id: connection.id)
      expect(outcome.iteration.ci_metadata["trigger"]).to include("status" => "triggered", "externalId" => "9876")

      expect(stub.with(body: { "ref" => "main", "inputs" => inputs_for(outcome), "return_run_details" => true }))
        .to have_been_requested
    end

    it "keeps the run and records the provider error when the dispatch fails" do
      stub_request(:post, %r{api\.github\.com/repos/my-org/shop/actions/workflows/e2e\.yml/dispatches})
        .to_return(status: 422, headers: { "Content-Type" => "application/json" },
                   body: { message: "Unexpected inputs provided: [\"op_grep\"]" }.to_json)

      outcome = trigger(connection).result
      expect(outcome).not_to be_triggered
      expect(outcome.error).to eq("HTTP 422: Unexpected inputs provided: [\"op_grep\"]")
      expect(outcome.run.reload).to have_attributes(ci_trigger_status: "failed", ci_trigger_error: outcome.error)
      expect(outcome.iteration.reload.ci_metadata.dig("trigger", "status")).to eq("failed")
    end

    it "never leaks the token into the recorded error" do
      stub_request(:post, %r{\Ahttps://api\.github\.com/}).to_return(status: 401,
                                                                     body: { message: "bad ghp_trigger_secret" }.to_json)
      outcome = trigger(connection).result
      expect(outcome.error).to eq("HTTP 401: bad [FILTERED]")
      expect(outcome.run.reload.ci_trigger_error).not_to include("ghp_trigger_secret")
    end

    it "reports network errors without raising" do
      stub_request(:post, %r{\Ahttps://api\.github\.com/}).to_timeout
      outcome = trigger(connection).result
      expect(outcome.status).to eq("failed")
      expect(outcome.error).to be_present
    end

    it "does nothing when the contract fails" do
      call = described_class.new(user: create(:user)).call(project:, connection:, suite:)
      expect(call).to be_failure
      expect(TestManagement::TestRun.where(project_id: project.id)).to be_empty
      expect(a_request(:post, %r{\Ahttps?://api\.github\.com(?:/|\z)})).not_to have_been_made
    end
  end

  describe "new_iteration" do
    let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }
    let!(:run) { create(:tm_test_run, project:, name: "Regression") }

    before do
      create(:tm_test_run_case, test_run: run, test_case: case_a)
      stub_request(:post, %r{\Ahttps://api\.github\.com/}).to_return(status: 204)
    end

    it "starts the next iteration of the run and adds missing cases of the scope" do
      first = trigger(connection, mode: "new_iteration", run:, suite: nil).result
      expect(first.iteration.number).to eq(1)
      expect(first.grep).to eq("adds\\ item")
      expect(first.url).to eq("https://github.com/my-org/shop/actions/workflows/e2e.yml")

      second = trigger(connection, mode: "new_iteration", run:, test_case: case_b, suite: nil).result
      expect(second.run).to eq(run)
      expect(second.iteration.number).to eq(2)
      expect(run.reload.current_iteration).to eq(second.iteration)
      expect(run.run_cases.pluck(:test_case_id)).to contain_exactly(case_a.id, case_b.id)
    end
  end
end

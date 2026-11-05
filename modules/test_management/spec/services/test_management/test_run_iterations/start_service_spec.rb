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

RSpec.describe TestManagement::TestRunIterations::StartService do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs execute_test_runs] })
  end
  shared_let(:tester) { create(:user, member_with_permissions: { project => %i[view_test_runs execute_test_runs] }) }

  let(:run) { create(:tm_test_run, :in_progress, project:) }
  let!(:passed_case) { create(:tm_test_run_case, test_run: run, status: "passed") }
  let!(:failed_case) { create(:tm_test_run_case, test_run: run, status: "failed") }

  def start(user = manager, **params)
    described_class.new(user:, run:).call(params)
  end

  it "keeps earlier results in iteration 1 and resets the run cases for iteration 2" do
    old_result = create(:tm_test_result, run_case: failed_case, status: "failed")

    call = start(name: "Release 2.4 RC1")

    expect(call).to be_success
    iteration = call.result
    expect(iteration).to have_attributes(number: 2, name: "Release 2.4 RC1", source: "manual", created_by: manager)
    first = run.iterations.find_by(number: 1)
    expect(old_result.reload.iteration).to eq(first)
    expect(run.run_cases.reload.map(&:status)).to all(eq("untested"))
    expect(run.reload.state).to eq("new")
    expect(first.status_counts).to include("failed" => 1)
    expect(iteration.status_counts).to include("untested" => 2)
  end

  it "creates iteration 1 without resetting anything when the run has no results yet" do
    passed_case.update_column(:status, "untested")
    failed_case.update_column(:status, "untested")

    expect(start.result.number).to eq(1)
    expect(start.result.number).to eq(2)
  end

  it "records new manual results in the current iteration" do
    start
    current = run.reload.current_iteration
    TestManagement::RunCases::UpdateService.new(user: manager, model: passed_case.reload).call(status: "passed")

    expect(passed_case.results.last.iteration).to eq(current)
  end

  it "needs add_test_runs and an active run" do
    expect(start(tester)).to be_failure
    run.update_columns(state: "completed", finished_at: Time.current)
    expect(start).to be_failure
    expect(run.iterations).to be_empty
  end
end

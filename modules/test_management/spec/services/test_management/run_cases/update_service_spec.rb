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

RSpec.describe TestManagement::RunCases::UpdateService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:tester) { create(:user, member_with_permissions: { project => %i[view_test_runs execute_test_runs] }) }
  let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_runs] }) }
  let(:run) { create(:tm_test_run, project:) }
  let(:run_case) { create(:tm_test_run_case, test_run: run) }

  def update(params = nil, user: tester, **attributes)
    described_class.new(user:, model: run_case).call(params || attributes)
  end

  it "changes the status, writes a result and starts the run" do
    result = update(status: "failed", comment: "500 on submit")

    expect(result).to be_success
    expect(run_case.reload.status).to eq("failed")
    expect(run_case.results.last).to have_attributes(status: "failed", comment: "500 on submit", user: tester)
    expect(run.reload.state).to eq("in_progress")
  end

  it "keeps a new run new when the status stays untested" do
    update(status: "untested")
    expect(run.reload.state).to eq("new")
    expect(run_case.results).to be_empty
  end

  it "writes a result for a comment without a status change" do
    update(status: "untested", comment: "waiting for env")
    expect(run_case.results.last.comment).to eq("waiting for env")
  end

  it "changes the assignee to a project member and can unassign" do
    expect(update(assigned_to_id: tester.id.to_s)).to be_success
    expect(run_case.reload.assigned_to).to eq(tester)

    expect(update(assigned_to_id: "")).to be_success
    expect(run_case.reload.assigned_to).to be_nil
  end

  it "rejects non-member assignees" do
    result = update(assigned_to_id: create(:user).id.to_s)
    expect(result.errors.symbols_for(:base)).to include(:tm_invalid_assignee)
  end

  it "rejects unknown statuses" do
    result = update(status: "maybe")
    expect(result.errors.symbols_for(:base)).to include(:tm_invalid_status)
  end

  it "rejects users without execute permission" do
    result = update({ status: "passed" }, user: viewer)
    expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
  end

  it "rejects changes in a finished run" do
    run.update!(state: "completed")
    result = update(status: "passed")

    expect(result.errors.symbols_for(:base)).to include(:tm_run_finished)
    expect(run_case.reload.status).to eq("untested")
  end
end

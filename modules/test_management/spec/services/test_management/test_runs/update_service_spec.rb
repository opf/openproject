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

RSpec.describe TestManagement::TestRuns::UpdateService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs] }) }
  let(:cases) { create_list(:tm_test_case, 3, project:) }
  let(:run) { create(:tm_test_run, project:) }

  before { cases.first(2).each { |c| create(:tm_test_run_case, test_run: run, test_case: c, status: "passed") } }

  def update(params)
    described_class.new(user:, model: TestManagement::TestRun.find(run.id)).call(params)
  end

  it "replaces the specific selection, keeping results of cases that stay" do
    result = update(test_case_ids: [cases[1].id.to_s, cases[2].id.to_s])

    expect(result).to be_success
    expect(run.reload.test_cases).to contain_exactly(cases[1], cases[2])
    expect(run.run_cases.find_by(test_case: cases[1]).status).to eq("passed")
    expect(run.run_cases.find_by(test_case: cases[2]).status).to eq("untested")
  end

  it "keeps the cases when no selection is submitted" do
    update(name: "Renamed")
    expect(run.reload.test_cases.count).to eq(2)
    expect(run.name).to eq("Renamed")
  end

  it "adds missing cases when switched to all" do
    update(selection_mode: "all")
    expect(run.reload.test_cases).to match_array(cases)
  end

  it "refuses to edit a finished run" do
    run.update!(state: "completed")
    expect(update(name: "x")).not_to be_success
  end
end

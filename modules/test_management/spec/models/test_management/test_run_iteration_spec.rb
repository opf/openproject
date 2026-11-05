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

RSpec.describe TestManagement::TestRunIteration do
  let(:run) { create(:tm_test_run, :in_progress) }
  let!(:case_a) { create(:tm_test_run_case, test_run: run) }
  let!(:case_b) { create(:tm_test_run_case, test_run: run) }
  let(:first) { create(:tm_test_run_iteration, test_run: run, number: 1) }
  let(:second) { create(:tm_test_run_iteration, test_run: run, number: 2, name: "RC 1") }

  it "labels iterations and knows the current one" do
    expect(first.label).to eq("#1")
    expect(second.display_name).to eq("RC 1")
    expect(second.label).to eq("#2 · RC 1")
    expect(first).not_to be_current
    expect(second).to be_current
    expect(run.reload.current_iteration).to eq(second)
    expect(run.iterations_count).to eq(2)
  end

  it "counts the latest result of each run case within the iteration" do
    create(:tm_test_result, run_case: case_a, status: "failed", iteration: first)
    create(:tm_test_result, run_case: case_a, status: "passed", iteration: first)
    create(:tm_test_result, run_case: case_b, status: "failed", iteration: second)

    expect(first.run_case_statuses).to eq(case_a.id => "passed", case_b.id => "untested")
    expect(first.status_counts).to include("passed" => 1, "untested" => 1, "failed" => 0)
    expect(second.status_counts).to include("failed" => 1, "untested" => 1)
    expect(first.passed_percent).to eq(50)
  end

  it "counts several iterations in one go with the same result as one by one" do
    create(:tm_test_result, run_case: case_a, status: "failed", iteration: first)
    create(:tm_test_result, run_case: case_a, status: "passed", iteration: first)
    create(:tm_test_result, run_case: case_b, status: "blocked", iteration: second)
    ids = [case_a.id, case_b.id]

    counts = described_class.status_counts_for([first, second], ids)

    expect(counts[first.id]).to eq(first.status_counts(ids))
    expect(counts[second.id]).to eq(second.status_counts(ids))
  end

  it "preloads collection stats: the current iteration shows the run's live counts" do
    create(:tm_test_result, run_case: case_a, status: "failed", iteration: first)
    second
    case_b.update!(status: "passed")

    first_loaded, second_loaded = described_class.preload_stats(run.iterations.order(:number), run)

    expect(first_loaded.preloaded_current).to be(false)
    expect(first_loaded.preloaded_status_counts).to include("failed" => 1, "untested" => 1)
    expect(second_loaded.preloaded_current).to be(true)
    expect(second_loaded.preloaded_status_counts).to eq(run.status_counts)
  end

  it "requires unique numbers per run" do
    first
    expect(build(:tm_test_run_iteration, test_run: run, number: 1)).not_to be_valid
  end
end

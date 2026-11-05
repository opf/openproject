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

RSpec.describe TestManagement::TestRun do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:run) { create(:tm_test_run, project:) }

  describe "validations" do
    it "requires a name, a known state and a known selection mode" do
      expect(build(:tm_test_run, name: "")).not_to be_valid
      expect(build(:tm_test_run, state: "open")).not_to be_valid
      expect(build(:tm_test_run, selection_mode: "random")).not_to be_valid
    end

    it "requires end date >= start date" do
      run = build(:tm_test_run, start_date: Date.new(2026, 11, 5), end_date: Date.new(2026, 11, 1))
      expect(run).not_to be_valid
      expect(run.errors[:end_date]).to be_present
    end
  end

  describe "ids" do
    it "uses global, increasing numeric ids shown as R<id>" do
      first = create(:tm_test_run, project:)
      second = create(:tm_test_run, project: create(:project))

      expect(second.id).to be > first.id
      expect(first.formatted_id).to eq("R#{first.id}")
    end

    it "never reuses the id of a deleted run" do
      old_id = run.id
      run.destroy
      expect(create(:tm_test_run, project:).id).to be > old_id
    end
  end

  describe "states" do
    it "is active while new or in progress" do
      expect(build(:tm_test_run)).to be_active
      expect(build(:tm_test_run, :in_progress)).to be_active
      expect(build(:tm_test_run, :completed)).to be_finished
      expect(build(:tm_test_run, :cancelled)).to be_finished
    end

    it "scopes active runs and runs in a state" do
      active = create(:tm_test_run, project:)
      done = create(:tm_test_run, :completed, project:)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(done)
      expect(described_class.in_state("completed")).to contain_exactly(done)
    end

    it "auto-adds only in all mode while active" do
      expect(build(:tm_test_run, selection_mode: "all")).to be_auto_adds_cases
      expect(build(:tm_test_run, selection_mode: "specific")).not_to be_auto_adds_cases
      expect(build(:tm_test_run, :completed, selection_mode: "all")).not_to be_auto_adds_cases
    end
  end

  describe "#matching_cases_scope" do
    let(:suite) { create(:tm_suite, project:) }
    let(:sub) { create(:tm_suite, project:, parent: suite) }
    let!(:automated_in_sub) { create(:tm_test_case, project:, suite: sub, automated: true) }
    let!(:manual_elsewhere) { create(:tm_test_case, project:, automated: false) }

    it "returns every case in all mode" do
      run = build(:tm_test_run, project:, selection_mode: "all")
      expect(run.matching_cases_scope).to contain_exactly(automated_in_sub, manual_elsewhere)
    end

    it "returns nothing in specific mode" do
      expect(build(:tm_test_run, project:).matching_cases_scope).to be_empty
    end

    it "filters by automation and folder subtree" do
      run = build(:tm_test_run, project:, selection_mode: "all",
                                filter_options: { "automation" => "automated", "suite_ids" => [suite.id] })
      expect(run.matching_cases_scope).to contain_exactly(automated_in_sub)
      expect(run.matches?(automated_in_sub)).to be(true)
      expect(run.matches?(manual_elsewhere)).to be(false)
    end

    it "filters manual cases" do
      run = build(:tm_test_run, project:, selection_mode: "all", filter_options: { "automation" => "manual" })
      expect(run.matching_cases_scope).to contain_exactly(manual_elsewhere)
    end

    it "never matches foreign cases" do
      run = build(:tm_test_run, project:, selection_mode: "all")
      expect(run.matches?(create(:tm_test_case))).to be(false)
    end
  end

  describe "#add_cases! and statistics" do
    let(:assignee) { create(:user) }
    let(:run) { create(:tm_test_run, project:, selection_mode: "all", assigned_to: assignee) }

    it "adds missing cases as untested, assigned to the run assignee, without duplicates" do
      cases = create_list(:tm_test_case, 2, project:)
      run.add_cases!
      run.add_cases!

      expect(run.run_cases.count).to eq(2)
      expect(run.run_cases.map(&:status).uniq).to eq(["untested"])
      expect(run.run_cases.map(&:assigned_to_id).uniq).to eq([assignee.id])
      expect(run.test_cases).to match_array(cases)
    end

    it "counts statuses (final status wins) and computes the pass rate" do
      run = create(:tm_test_run, project:, selection_mode: "specific")
      create(:tm_test_run_case, test_run: run, status: "passed")
      create(:tm_test_run_case, test_run: run, status: "failed")
      create(:tm_test_run_case, test_run: run, status: "untested", final_status: "untested")

      expect(run.status_counts).to eq("passed" => 1, "failed" => 1, "blocked" => 0, "retest" => 0,
                                      "in_progress" => 0, "skipped" => 0, "untested" => 1)
      expect(run.total_cases).to eq(3)
      expect(run.passed_percent).to eq(33)
    end

    it "returns 0% for an empty run" do
      expect(run.passed_percent).to eq(0)
    end
  end

  describe ".preload_stats" do
    let(:other) { create(:tm_test_run, project:) }

    before do
      create(:tm_test_run_case, test_run: run, status: "passed")
      create(:tm_test_run_case, test_run: run, status: "failed")
      create(:tm_test_run_case, test_run: other)
      create(:tm_test_run_iteration, test_run: run, number: 1)
      create(:tm_test_run_iteration, test_run: run, number: 2)
      create(:tm_automation_import, test_run: run, unmatched_count: 3)
      create(:tm_automation_import, test_run: run, unmatched_count: 4)
    end

    def stats(record)
      [record.status_counts, record.current_iteration_number, record.iterations_count, record.unmatched_tests_count]
    end

    it "returns the same values as the per-run queries, without further queries per run" do
      expected = [run, other].map { |r| stats(described_class.find(r.id)) }
      preloaded = described_class.preload_stats(described_class.where(id: [run.id, other.id]).order(:id))

      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(preloaded.map { |r| stats(r) }).to eq(expected)
      end
      expect(queries).to be_empty
      expect(expected.first).to eq([run.status_counts, 2, 2, 7])
    end

    it "drops the snapshot on reload" do
      loaded = described_class.preload_stats([described_class.find(run.id)]).first
      create(:tm_test_run_iteration, test_run: run, number: 3)

      expect(loaded.iterations_count).to eq(2)
      expect(loaded.reload.iterations_count).to eq(3)
    end
  end
end

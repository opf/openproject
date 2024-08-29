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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

# This file can be safely deleted once the feature flag :percent_complete_edition
# is removed, which should happen for OpenProject 15.0 release.
RSpec.describe WorkPackages::Progress::ApplyStatusesChangeJob, "pre 14.4 without percent complete edition",
               with_flag: { percent_complete_edition: false } do
  shared_let(:author) { create(:user) }
  shared_let(:priority) { create(:priority, name: "Normal") }
  shared_let(:project) { create(:project, name: "Main project") }

  # statuses for work-based mode
  shared_let(:status_new) { create(:status, name: "New") }
  shared_let(:status_wip) { create(:status, name: "In progress") }
  shared_let(:status_closed) { create(:status, name: "Closed") }

  # statuses for status-based mode
  shared_let(:status_0p_todo) { create(:status, name: "To do (0%)", default_done_ratio: 0) }
  shared_let(:status_40p_doing) { create(:status, name: "Doing (40%)", default_done_ratio: 40) }
  shared_let(:status_100p_done) { create(:status, name: "Done (100%)", default_done_ratio: 100) }

  # statuses for both work-based and status-based modes
  shared_let(:status_excluded) { create(:status, :excluded_from_totals, name: "Excluded") }

  before_all do
    set_factory_default(:user, author)
    set_factory_default(:priority, priority)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status_new)
  end

  subject(:job) { described_class }

  def expect_performing_job_changes(from:, to:,
                                    cause_type: "status_changed",
                                    status_name: "Some status name",
                                    status_id: 99,
                                    changes: { "default_done_ratio" => [33, 66] })
    table = create_table(from)

    job.perform_now(cause_type:, status_name:, status_id:, changes:)

    table.work_packages.map(&:reload)
    expect_work_packages(table.work_packages, to)

    table.work_packages
  end

  context "when in work-based mode",
          with_settings: { work_package_done_ratio: "field" } do
    context "when some work packages have % complete value different from their status" do
      it "does not change any of their progress values" do
        expect_performing_job_changes(
          from: <<~TABLE,
            subject     | status      | % complete
            wp          | Doing (40%) |
            wp 0%       | To do (0%)  |        55%
            wp 40%      | Doing (40%) |        55%
            wp 100%     | Done (100%) |        55%
          TABLE
          to: <<~TABLE
            subject     | status      | % complete
            wp          | Doing (40%) |
            wp 0%       | To do (0%)  |        55%
            wp 40%      | Doing (40%) |        55%
            wp 100%     | Done (100%) |        55%
          TABLE
        )
      end
    end

    context "when some work packages have work set to 0h and a % complete value being set" do
      it "clears the % complete valuedoes not change any of their progress values" do
        expect_performing_job_changes(
          from: <<~TABLE,
            hierarchy    | status      | work | remaining work | % complete
            wp 10h 40%   | To do (0%)  |  10h |             6h |        40%
            wp 0h 0%     | To do (0%)  |   0h |             0h |         0%
            wp 0h 40%    | Doing (40%) |   0h |             0h |        40%
            wp 0h 100%   | Done (100%) |   0h |             0h |       100%
          TABLE
          to: <<~TABLE
            subject      | status      | work | remaining work | % complete
            wp 10h 40%   | To do (0%)  |  10h |             6h |        40%
            wp 0h 0%     | To do (0%)  |   0h |             0h |
            wp 0h 40%    | Doing (40%) |   0h |             0h |
            wp 0h 100%   | Done (100%) |   0h |             0h |
          TABLE
        )
      end
    end

    context "when a status is being excluded from progress calculation" do
      it "computes totals of the parent having work when all children are excluded" do
        expect_performing_job_changes(
          from: <<~TABLE,
            hierarchy   | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent      | In progress |  10h |             3h |        70% |    20h |               5h |          75%
              child     | Excluded    |  10h |             2h |        50% |        |                  |
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent      | In progress |  10h |             3h |        70% |    10h |               3h |          70%
              child     | Excluded    |  10h |             2h |        50% |        |                  |
          TABLE
        )
      end

      it "keeps the totals unset if work, remaining work, and % complete are all nil" do
        expect_performing_job_changes(
          from: <<~TABLE,
            hierarchy   | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent      | In progress |      |                |            |        |                  |
              child     | Excluded    |      |                |            |        |                  |
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent      | In progress |      |                |            |        |                  |
              child     | Excluded    |      |                |            |        |                  |
          TABLE
        )
      end

      describe "general case" do
        # The work packages are created like if the status is not excluded yet
        shared_let_work_packages(<<~TABLE)
          hierarchy    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          grandparent  | New         |   1h |           0.6h |        40% |    24h |            11.3h |          53%
            parent     | Excluded    |   4h |             1h |        75% |    23h |            10.7h |          53%
              child 1  | Excluded    |   9h |           7.2h |        20% |        |                  |
              child 2  | In progress |   5h |           2.5h |        50% |        |                  |
              child 3  | Closed      |   5h |             0h |       100% |        |                  |
        TABLE

        before do
          job.perform_now(
            cause_type: "status_changed",
            status_name: status_excluded.name,
            status_id: status_excluded.id,
            changes: { "excluded_from_totals" => [false, true] }
          )
          table_work_packages.map(&:reload)
        end

        it "recomputes totals without the values from work packages having the excluded status" do
          expect_work_packages(table_work_packages, <<~TABLE)
            subject      | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            grandparent  | New         |   1h |           0.6h |        40% |    11h |             3.1h |          72%
              parent     | Excluded    |   4h |             1h |        75% |    10H |             2.5h |          75%
                child 1  | Excluded    |   9h |           7.2h |        20% |        |                  |
                child 2  | In progress |   5h |           2.5h |        50% |        |                  |
                child 3  | Closed      |   5h |             0h |       100% |        |                  |
          TABLE
        end

        it "adds a relevant journal entry for the parent with recomputed total" do
          changed_worked_packages = [grandparent, parent]
          changed_worked_packages.each do |work_package|
            expect(work_package.journals.count).to eq(2), "expected #{work_package} to have a new journal"
            last_journal = work_package.last_journal
            expect(last_journal.user).to eq(User.system)
            expect(last_journal.cause_type).to eq("status_changed")
            expect(last_journal.cause_status_name).to eq("Excluded")
            expect(last_journal.cause_status_id).to eq(status_excluded.id)
            expect(last_journal.cause_status_changes).to eq({ "excluded_from_totals" => [false, true] })
          end

          unchanged_work_packages = table_work_packages - changed_worked_packages
          unchanged_work_packages.each do |work_package|
            expect(work_package.journals.count).to eq(1), "expected #{work_package} not to have new journals"
          end
        end
      end
    end
  end

  context "when in status-based mode",
          with_settings: { work_package_done_ratio: "status" } do
    context "when work packages have % complete value different from their status" do
      it "updates the work packages % complete value from the status" do
        expect_performing_job_changes(
          from: <<~TABLE,
            subject     | status      | % complete
            wp          | Doing (40%) |
            wp 0%       | To do (0%)  |        50%
            wp 40%      | Doing (40%) |        50%
            wp 100%     | Done (100%) |        50%
          TABLE
          to: <<~TABLE
            subject     | status      | % complete
            wp          | Doing (40%) |        40%
            wp 0%       | To do (0%)  |         0%
            wp 40%      | Doing (40%) |        40%
            wp 100%     | Done (100%) |       100%
          TABLE
        )
      end
    end

    context "when work packages have work and remaining work values" do
      it "updates the work packages remaining work along with the % complete value from the status" do
        expect_performing_job_changes(
          from: <<~TABLE,
            subject     | status      | work | remaining work | % complete
            wp          | Doing (40%) |  10h |                |
            wp 0%       | To do (0%)  |  10h |             5h |        50%
            wp 40%      | Doing (40%) |  10h |             5h |        50%
            wp 100%     | Done (100%) |  10h |             5h |        50%
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete
            wp          | Doing (40%) |  10h |             6h |        40%
            wp 0%       | To do (0%)  |  10h |            10h |         0%
            wp 40%      | Doing (40%) |  10h |             6h |        40%
            wp 100%     | Done (100%) |  10h |             0h |       100%
          TABLE
        )
      end
    end

    context "when in hierarchy" do
      it "the total remaining work and total % complete values are recomputed" do
        # Simulating changing "Doing" status default % progress from 20% to 40%
        expect_performing_job_changes(
          from: <<~TABLE,
            hierarchy    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            grandparent  | Doing (40%) |   1h |           0.8h |        20% |    20h |             9.8h |          51%
              parent     | Doing (40%) |      |                |        20% |    19h |               9h |          53%
                child 1  | Done (100%) |   9h |             0h |       100% |        |                  |
                child 2  | Doing (40%) |   5h |             4h |        20% |        |                  |
                child 3  | To do (0%)  |   5h |             5h |         0% |        |                  |
          TABLE
          to: <<~TABLE
            subject      | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            grandparent  | Doing (40%) |   1h |           0.6h |        40% |    20h |             8.6h |          57%
              parent     | Doing (40%) |      |                |        40% |    19h |               8h |          58%
                child 1  | Done (100%) |   9h |             0h |       100% |        |                  |
                child 2  | Doing (40%) |   5h |             3h |        40% |        |                  |
                child 3  | To do (0%)  |   5h |             5h |         0% |        |                  |
          TABLE
        )
      end
    end

    context "when a status is being excluded from progress calculation" do
      # The work packages are created like if the status is not excluded yet
      shared_let_work_packages(<<~TABLE)
        hierarchy    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
        grandparent  | Doing (40%) |   1h |           0.6h |        40% |    24h |            16.6h |          31%
          parent     | Excluded    |   4h |             4h |         0% |    23h |              16h |          30%
            child 1  | Excluded    |   9h |             9h |         0% |        |                  |
            child 2  | Doing (40%) |   5h |             3h |        40% |        |                  |
            child 3  | Done (100%) |   5h |             0h |       100% |        |                  |
      TABLE

      before do
        job.perform_now(
          cause_type: "status_changed",
          status_name: status_excluded.name,
          status_id: status_excluded.id,
          changes: { "excluded_from_totals" => [false, true] }
        )
        table_work_packages.map(&:reload)
      end

      it "recomputes totals without the values from work packages having the excluded status" do
        expect_work_packages(table_work_packages, <<~TABLE)
          subject      | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          grandparent  | Doing (40%) |   1h |           0.6h |        40% |    11h |             3.6h |          67%
            parent     | Excluded    |   4h |             4h |         0% |    10h |               3h |          70%
              child 1  | Excluded    |   9h |             9h |         0% |        |                  |
              child 2  | Doing (40%) |   5h |             3h |        40% |        |                  |
              child 3  | Done (100%) |   5h |             0h |       100% |        |                  |
        TABLE
      end

      it "adds a relevant journal entry for the parent with recomputed total" do
        changed_worked_packages = [grandparent, parent]
        changed_worked_packages.each do |work_package|
          expect(work_package.journals.count).to eq(2), "expected #{work_package} to have a new journal"
          last_journal = work_package.last_journal
          expect(last_journal.user).to eq(User.system)
          expect(last_journal.cause_type).to eq("status_changed")
          expect(last_journal.cause_status_name).to eq("Excluded")
          expect(last_journal.cause_status_id).to eq(status_excluded.id)
          expect(last_journal.cause_status_changes).to eq({ "excluded_from_totals" => [false, true] })
        end

        unchanged_work_packages = table_work_packages - changed_worked_packages
        unchanged_work_packages.each do |work_package|
          expect(work_package.journals.count).to eq(1), "expected #{work_package} not to have new journals"
        end
      end
    end

    describe "journals" do
      # rubocop:disable RSpec/ExampleLength
      it "creates journal entries for modified work packages on status % complete change" do
        parent, child1, child2 = expect_performing_job_changes(
          from: <<~TABLE,
            hierarchy  | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent     | To do (0%)  |      |                |         0% |    20h |               8h |          60%
              child 1  | Doing (40%) |  10h |             8h |        20% |        |                  |
              child 2  | Done (100%) |  10h |             0h |       100% |        |                  |
          TABLE
          to: <<~TABLE,
            subject    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent     | To do (0%)  |      |                |         0% |    20h |               6h |          70%
              child 1  | Doing (40%) |  10h |             6h |        40% |        |                  |
              child 2  | Done (100%) |  10h |             0h |       100% |        |                  |
          TABLE
          cause_type: "status_changed",
          status_name: status_40p_doing.name,
          status_id: status_40p_doing.id,
          changes: { "default_done_ratio" => [20, 40] }
        )
        [parent, child1].each do |work_package|
          expect(work_package.journals.count).to eq 2
          last_journal = work_package.last_journal
          expect(last_journal.user).to eq(User.system)
          expect(last_journal.cause_type).to eq("status_changed")
          expect(last_journal.cause_status_name).to eq("Doing (40%)")
          expect(last_journal.cause_status_id).to eq(status_40p_doing.id)
          expect(last_journal.cause_status_changes).to eq({ "default_done_ratio" => [20, 40] })
        end

        # unchanged => no new journals
        expect(child2.journals.count).to eq 1
      end
      # rubocop:enable RSpec/ExampleLength

      it "creates journal entries for modified work packages on progress calculation mode set to status-based" do
        parent, child1, child2 = expect_performing_job_changes(
          from: <<~TABLE,
            hierarchy  | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent     | To do (0%)  |      |                |         0% |    20h |               8h |          60%
              child 1  | Doing (40%) |  10h |             8h |        20% |        |                  |
              child 2  | Done (100%) |  10h |             0h |       100% |        |                  |
          TABLE
          to: <<~TABLE,
            subject    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent     | To do (0%)  |      |                |         0% |    20h |               6h |          70%
              child 1  | Doing (40%) |  10h |             6h |        40% |        |                  |
              child 2  | Done (100%) |  10h |             0h |       100% |        |                  |
          TABLE
          cause_type: "progress_mode_changed_to_status_based"
        )
        [parent, child1].each do |work_package|
          expect(work_package.journals.count).to eq 2
          last_journal = work_package.last_journal
          expect(last_journal.user).to eq(User.system)
          expect(last_journal.cause_type).to eq("progress_mode_changed_to_status_based")
        end

        # unchanged => no new journals
        expect(child2.journals.count).to eq 1
      end
    end
  end

  context "with errors during job execution",
          with_settings: { work_package_done_ratio: "status" } do
    let_work_packages(<<~TABLE)
      subject     | status      | % complete
      wp          | Doing (40%) |
      wp 0%       | To do (0%)  |        50%
      wp 40%      | Doing (40%) |        50%
      wp 100%     | Done (100%) |        50%
    TABLE

    before do
      allow(Journals::CreateService)
        .to receive(:new)
              .and_call_original

      allow(Journals::CreateService)
        .to receive(:new)
              .with(WorkPackage.last, User.system)
              .and_return(nil)

      begin
        job.perform_now(cause_type: "status_changed",
                        status_name: "New",
                        status_id: 99,
                        changes: { "default_done_ratio" => [33, 66] })
      rescue StandardError
      end
    end

    it "does not update any work package" do
      expect_work_packages(WorkPackage.all, <<~TABLE)
        subject     | status      | % complete
        wp          | Doing (40%) |
        wp 0%       | To do (0%)  |        50%
        wp 40%      | Doing (40%) |        50%
        wp 100%     | Done (100%) |        50%
      TABLE
    end
  end
end

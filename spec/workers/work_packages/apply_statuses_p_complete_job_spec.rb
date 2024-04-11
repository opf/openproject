#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe WorkPackages::ApplyStatusesPCompleteJob do
  shared_let(:author) { create(:user) }
  shared_let(:priority) { create(:priority, name: "Normal") }
  shared_let(:project) { create(:project, name: "Main project") }
  shared_let(:status_new) { create(:status, name: "New") }

  before_all do
    set_factory_default(:user, author)
    set_factory_default(:priority, priority)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status_new)
  end

  shared_let(:status_0p_todo) { create(:status, name: "To do (0%)", default_done_ratio: 0) }
  shared_let(:status_40p_doing) { create(:status, name: "Doing (40%)", default_done_ratio: 40) }
  shared_let(:status_100p_done) { create(:status, name: "Done (100%)", default_done_ratio: 100) }

  subject(:job) { described_class }

  def expect_performing_job_changes(from:, to:,
                                    cause_type: "status_p_complete_changed",
                                    status_name: "New",
                                    status_id: 99,
                                    change: [33, 66])
    table = create_table(from)

    job.perform_now(cause_type:, status_name:, status_id:, change:)

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
                child 1  | Done (100%) |   9h |             0h |       100% |     9h |               0h |         100%
                child 2  | Doing (40%) |   5h |             4h |        20% |     5h |               4h |          20%
                child 3  | To do (0%)  |   5h |             5h |         0% |     5h |               5h |           0%
          TABLE
          to: <<~TABLE
            subject      | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            grandparent  | Doing (40%) |   1h |           0.6h |        40% |    20h |             8.6h |          57%
              parent     | Doing (40%) |      |                |        40% |    19h |               8h |          58%
                child 1  | Done (100%) |   9h |             0h |       100% |     9h |               0h |         100%
                child 2  | Doing (40%) |   5h |             3h |        40% |     5h |               3h |          40%
                child 3  | To do (0%)  |   5h |             5h |         0% |     5h |               5h |           0%
          TABLE
        )
      end
    end

    describe "journals" do
      # rubocop:disable RSpec/ExampleLength
      it "creates journal entries for modified work packages on status % complete change" do
        parent, child1, child2 = expect_performing_job_changes(
          from: <<~TABLE,
            hierarchy  | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent     | To do (0%)  |      |                |         0% |    20h |               8h |          60%
              child 1  | Doing (40%) |  10h |             8h |        20% |    10h |               8h |          20%
              child 2  | Done (100%) |  10h |             0h |       100% |    10h |               0h |         100%
          TABLE
          to: <<~TABLE,
            subject    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent     | To do (0%)  |      |                |         0% |    20h |               6h |          70%
              child 1  | Doing (40%) |  10h |             6h |        40% |    10h |               6h |          40%
              child 2  | Done (100%) |  10h |             0h |       100% |    10h |               0h |         100%
          TABLE
          cause_type: "status_p_complete_changed",
          status_name: status_40p_doing.name,
          status_id: status_40p_doing.id,
          change: [20, 40]
        )
        [parent, child1].each do |work_package|
          expect(work_package.journals.count).to eq 2
          last_journal = work_package.last_journal
          expect(last_journal.user).to eq(User.system)
          expect(last_journal.cause_type).to eq("status_p_complete_changed")
          expect(last_journal.cause_status_name).to eq("Doing (40%)")
          expect(last_journal.cause_status_id).to eq(status_40p_doing.id)
          expect(last_journal.cause_status_p_complete_change).to eq([20, 40])
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
              child 1  | Doing (40%) |  10h |             8h |        20% |    10h |               8h |          20%
              child 2  | Done (100%) |  10h |             0h |       100% |    10h |               0h |         100%
          TABLE
          to: <<~TABLE,
            subject    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent     | To do (0%)  |      |                |         0% |    20h |               6h |          70%
              child 1  | Doing (40%) |  10h |             6h |        40% |    10h |               6h |          40%
              child 2  | Done (100%) |  10h |             0h |       100% |    10h |               0h |         100%
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
end

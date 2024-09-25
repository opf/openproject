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

RSpec.describe WorkPackages::Progress::ApplyTotalPercentCompleteModeChangeJob do
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
                                    cause_type: "total_percent_complete_mode_changed_to_work_weighted_average",
                                    mode: "work_weighted_average")
    table = create_table(from)

    job.perform_now(cause_type:, mode:)

    table.work_packages.map(&:reload)
    expect_work_packages(table.work_packages, to)

    table.work_packages
  end

  context "when changing from simple average to work weighted average mode",
          with_settings: { total_percent_complete_mode: "work_weighted_average" } do
    context "on a single-level hierarchy" do
      it "does not update the total % complete of the work packages" do
        expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            flat_wp_1 |  10h |        |             6h |                  |        40% |
            flat_wp_2 |  5h  |        |             3h |                  |        60% |
          TABLE
          to: <<~TABLE
            subject   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            flat_wp_1 |  10h |        |             6h |                  |        40% |
            flat_wp_2 |  5h  |        |             3h |                  |        60% |
          TABLE
        )
      end
    end

    context "on a two-level hierarchy with parents having total values" do
      it "updates the total % complete of parent work packages" do
        expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |  10h |    30h |             6h |              6h  |        40% |          70%
              child1  |  15h |        |             0h |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |   5h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |  10h |    30h |             6h |              6h  |        40% |          80%
              child1  |  15h |        |             0h |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |   5h |        |             0h |                  |       100% |
          TABLE
        )
      end
    end

    context "on a two-level hierarchy with only % complete values set" do
      it "unsets the % complete value from parents" do
        expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |      |        |                |                  |        40% |          70%
              child1  |      |        |                |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |      |        |                |                  |       100% |
          TABLE
          to: <<~TABLE
            subject   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |      |        |                |                  |        40% |
              child1  |      |        |                |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |      |        |                |                  |       100% |
          TABLE
        )
      end
    end

    context "on a multi-level hierarchy with only % complete values set" do
      it "unsets the % complete value from parents" do
        expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy       | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |      |        |                |                  |        40% |          65%
              child1        |      |        |                |                  |       100% |
              child2        |      |        |                |                  |        40% |
              child3        |      |        |                |                  |       100% |          80%
                grandchild1 |      |        |                |                  |        40% |
                grandchild2 |      |        |                |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |      |        |                |                  |        40% |
              child1        |      |        |                |                  |       100% |
              child2        |      |        |                |                  |        40% |
              child3        |      |        |                |                  |       100% |
                grandchild1 |      |        |                |                  |        40% |
                grandchild2 |      |        |                |                  |       100% |
          TABLE
        )
      end
    end

    context "on a multi-level hierarchy with work and remaining work values set" do
      it "updates the total % complete of parent work packages" do
        expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy       | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          63%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |          70%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          88%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |         100%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
        )
      end
    end

    context "on a multi-level hierarchy with work and remaining work values set " \
            "and a child with a status excluded from totals" do
      it "updates the total % complete of parent work packages excluding the child" do
        expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy       | status    | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          | New       |  10h  |    30h |             6h |              6h  |        40% |          63%
              child1        | New       |  15h  |        |             0h |                  |       100% |
              child2        | New       |       |        |                |                  |        40% |
              child3        | New       |   5h  |    5h  |             0h |              0h  |       100% |          70%
                grandchild1 | New       |       |        |                |                  |        40% |
                grandchild2 | Excluded  |   20h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | status    | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          | New       |  10h  |    30h |             6h |              6h  |        40% |          80%
              child1        | New       |  15h  |        |             0h |                  |       100% |
              child2        | New       |       |        |                |                  |        40% |
              child3        | New       |   5h  |     5h |             0h |              0h  |       100% |         100%
                grandchild1 | New       |       |        |                |                  |        40% |
                grandchild2 | Excluded  |   20h |        |             0h |                  |       100% |
          TABLE
        )
      end
    end

    context "when all work packages of the hierarchy are excluded" do
      it "removes all totals" do
        expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy   | status      | work | remaining work | % complete | ∑ % complete
            parent      | Excluded    |  40h |            12h |        70% |          72%
              child     | Excluded    |  10h |             2h |        80% |
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete | ∑ % complete
            parent      | Excluded    |  40h |            12h |        70% |
              child     | Excluded    |  10h |             2h |        80% |
          TABLE
        )
      end
    end

    describe "journal entries" do
      # rubocop:disable RSpec/ExampleLength
      it "creates journal entries for the modified work packages" do
        parent, child1, child2, child3, grandchild1, grandchild2 = expect_performing_job_changes(
          mode: "work_weighted_average",
          from: <<~TABLE,
            hierarchy       | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          63%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |          70%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          88%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |         100%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
        )
        [parent, child3].each do |work_package|
          expect(work_package.journals.count).to eq 2
          last_journal = work_package.last_journal
          expect(last_journal.user).to eq(User.system)
          expect(last_journal.cause_type).to eq("total_percent_complete_mode_changed_to_work_weighted_average")
        end

        # unchanged => no new journals
        [child1, child2, grandchild1, grandchild2].each do |work_package|
          expect(work_package.journals.count).to eq 1
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  context "when changing from work weighted average to simple average mode",
          with_settings: { total_percent_complete_mode: "simple_average" } do
    context "on a single-level hierarchy" do
      it "does not update the total % complete of the work packages" do
        expect_performing_job_changes(
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            flat_wp_1 |  10h |        |             6h |                  |        40% |
            flat_wp_2 |  5h  |        |             3h |                  |        60% |
          TABLE
          to: <<~TABLE
            subject   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            flat_wp_1 |  10h |        |             6h |                  |        40% |
            flat_wp_2 |  5h  |        |             3h |                  |        60% |
          TABLE
        )
      end
    end

    context "on a two-level hierarchy with parents having total values" do
      it "updates the total % complete of parent work packages" do
        expect_performing_job_changes(
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |  10h |    30h |             6h |              6h  |        40% |          80%
              child1  |  15h |        |             0h |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |   5h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |  10h |    30h |             6h |              6h  |        40% |          70%
              child1  |  15h |        |             0h |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |   5h |        |             0h |                  |       100% |
          TABLE
        )
      end
    end

    context "on a two-level hierarchy with only % complete values set" do
      it "sets the % complete value from parents" do
        expect_performing_job_changes(
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |      |        |                |                  |        40% |
              child1  |      |        |                |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |      |        |                |                  |       100% |
          TABLE
          to: <<~TABLE
            subject   | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent    |      |        |                |                  |        40% |          70%
              child1  |      |        |                |                  |       100% |
              child2  |      |        |                |                  |        40% |
              child3  |      |        |                |                  |       100% |
          TABLE
        )
      end
    end

    context "on a multi-level hierarchy with only % complete values set" do
      it "unsets the % complete value from parents" do
        expect_performing_job_changes(
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy       | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |      |        |                |                  |        40% |
              child1        |      |        |                |                  |       100% |
              child2        |      |        |                |                  |        40% |
              child3        |      |        |                |                  |       100% |
                grandchild1 |      |        |                |                  |        40% |
                grandchild2 |      |        |                |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |      |        |                |                  |        40% |          65%
              child1        |      |        |                |                  |       100% |
              child2        |      |        |                |                  |        40% |
              child3        |      |        |                |                  |       100% |          80%
                grandchild1 |      |        |                |                  |        40% |
                grandchild2 |      |        |                |                  |       100% |
          TABLE
        )
      end
    end

    context "on a multi-level hierarchy with work and remaining work values set" do
      it "updates the total % complete of parent work packages irrelevant of work values" do
        expect_performing_job_changes(
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy         | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          88%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |         100%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          65%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |          80%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
        )
      end
    end

    context "on a multi-level hierarchy with work and remaining work values set " \
            "and a child having a status excluded from totals" do
      it "updates the total % complete of parent work packages irrelevant of work values " \
         "excluding the child with the excluded status" do
        expect_performing_job_changes(
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy         | status   | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          | New      |  10h  |    50h |             6h |              6h  |        40% |          88%
              child1        | New      |  15h  |        |             0h |                  |       100% |
              child2        | New      |       |        |                |                  |        40% |
              child3        | Excluded |   5h  |    25h |             0h |              0h  |       100% |         100%
                grandchild1 | New      |       |        |                |                  |        40% |
                grandchild2 | New      |   20h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | status   | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          | New      |  10h  |    50h |             6h |              6h  |        40% |          60%
              child1        | New      |  15h  |        |             0h |                  |       100% |
              child2        | New      |       |        |                |                  |        40% |
              child3        | Excluded |   5h  |    25h |             0h |              0h  |       100% |         70%
                grandchild1 | New      |       |        |                |                  |        40% |
                grandchild2 | New      |   20h |        |             0h |                  |       100% |
          TABLE
        )
      end
    end

    context "when all work packages of the hierarchy are excluded" do
      it "removes all totals" do
        expect_performing_job_changes(
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy   | status      | % complete | ∑ % complete
            parent      | Excluded    |         0% |           0%
              child     | Excluded    |         0% |
          TABLE
          to: <<~TABLE
            subject     | status      | % complete | ∑ % complete
            parent      | Excluded    |         0% |
              child     | Excluded    |         0% |
          TABLE
        )
      end
    end

    describe "journal entries" do
      # rubocop:disable RSpec/ExampleLength
      it "creates journal entries for the modified work packages" do
        parent, child1, child2, child3, grandchild1, grandchild2 = expect_performing_job_changes(
          cause_type: "total_percent_complete_mode_changed_to_simple_average",
          mode: "simple_average",
          from: <<~TABLE,
            hierarchy         | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          88%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |         100%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
          to: <<~TABLE
            subject         | work  | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
            parent          |  10h  |    50h |             6h |              6h  |        40% |          65%
              child1        |  15h  |        |             0h |                  |       100% |
              child2        |       |        |                |                  |        40% |
              child3        |   5h  |    25h |             0h |              0h  |       100% |          80%
                grandchild1 |       |        |                |                  |        40% |
                grandchild2 |   20h |        |             0h |                  |       100% |
          TABLE
        )
        [parent, child3].each do |work_package|
          expect(work_package.journals.count).to eq 2
          last_journal = work_package.last_journal
          expect(last_journal.user).to eq(User.system)
          expect(last_journal.cause_type).to eq("total_percent_complete_mode_changed_to_simple_average")
        end

        # unchanged => no new journals
        [child1, child2, grandchild1, grandchild2].each do |work_package|
          expect(work_package.journals.count).to eq 1
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  context "with errors during job execution" do
    let_work_packages(<<~TABLE)
      subject     | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
      wp          |  10h |    10h |             6h |               6h |        40% |          40%
      wp 0%       |  10h |    10h |            10h |              10h |         0% |           0%
      wp 40%      |  10h |    10h |             6h |               6h |        40% |          40%
      wp 100%     |  10h |    10h |             0h |               0h |       100% |         100%
    TABLE

    before do
      job.perform_now(cause_type: "should make it blow up!",
                      mode: "work_weighted_average")
    rescue StandardError
      # Catch the error to continue the test
    end

    it "does not update any work package" do
      expect_work_packages(WorkPackage.all, <<~TABLE)
        subject     | work | ∑ work | remaining work | ∑ remaining work | % complete | ∑ % complete
        wp          |  10h |    10h |             6h |               6h |        40% |          40%
        wp 0%       |  10h |    10h |            10h |              10h |         0% |           0%
        wp 40%      |  10h |    10h |             6h |               6h |        40% |          40%
        wp 100%     |  10h |    10h |             0h |               0h |       100% |         100%
      TABLE
    end

    it "cleans up temporary database artifacts used throughout the job" do
      expect(
        ActiveRecord::Base.connection.table_exists?("temp_wp_progress_values")
      ).to be(false)
    end
  end
end

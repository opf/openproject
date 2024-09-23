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

require "spec_helper"
require Rails.root.join("db/migrate/20240402072213_update_progress_calculation.rb")

RSpec.describe UpdateProgressCalculation, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) do
    perform_enqueued_jobs do
      ActiveRecord::Migration.suppress_messages { described_class.new.up }
    end
  end

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

  def expect_migrates(from:, to:)
    table = create_table(from)

    run_migration

    table.work_packages.map(&:reload)
    expect_work_packages(table.work_packages, to)

    table.work_packages
  end

  describe "journal creation" do
    before do
      Setting.work_package_done_ratio = "field"
    end

    context "when a work package progress values are not changed" do
      let_work_packages(<<~TABLE)
        hierarchy                 | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
        wp all unset              |      |                |            |        |                  |
        wp only pc set            |      |                |        60% |        |                  |
        wp parent consistent      |  10h |             4h |        60% |    20h |               8h |          60%
          wp all set consistent   |  10h |             4h |        60% |        |                  |
      TABLE

      before do
        run_migration
      end

      it "does create a journal entry only for the work package with a total % complete" do
        expect(wp_all_unset.journals.count).to eq(1)
        expect(wp_only_pc_set.journals.count).to eq(1)
        expect(wp_all_set_consistent.journals.count).to eq(1)

        # This one will receive a journal entry since we treat the total % complete field
        # as if it was introduced by the migration (OP 14.0) even though the field existed before.
        # But the calculation was off and we did not present the activity on the field anyway.
        expect(wp_parent_consistent.journals.count).to eq(2)

        expect(wp_parent_consistent.last_journal.get_changes)
          .to include("derived_done_ratio" => [nil, 60],
                      "cause" => [nil, { "feature" => "progress_calculation_adjusted", "type" => "system_update" }])
      end
    end

    context "when some work package progress values are changed" do
      let_work_packages(<<~TABLE)
        subject                   | work | remaining work | % complete
        wp only w set             |  10h |                |
        wp only rw set            |      |             4h |
        wp both w and pc set      |  10h |                |        60%
        wp all set inconsistent   |  10h |             1h |        10%
      TABLE

      before do
        run_migration
      end

      it "creates one and only one additional journal entry" do
        table_work_packages.each do |wp|
          expect(wp.journals.count).to eq(2)
        end
      end

      it "the journal author is the system user" do
        journal = WorkPackage.last.last_journal
        expect(journal.user).to eq(User.system)
      end

      it "changes the lock_version of the work package" do
        previous_lock_version = wp_only_w_set.lock_version
        wp_only_w_set.reload
        expect(wp_only_w_set.lock_version).not_to eq(previous_lock_version)
      end

      it "changes the updated_at of the work package" do
        wp_only_w_set.reload
        expect(wp_only_w_set.updated_at).not_to eq(wp_only_w_set.created_at)
        first_journal = wp_only_w_set.journals.first
        expect(wp_only_w_set.updated_at).not_to eq(first_journal.updated_at)

        expect(wp_only_w_set.updated_at).to be > wp_only_w_set.created_at
        last_journal = wp_only_w_set.journals.last
        expect(wp_only_w_set.updated_at).to eq(last_journal.updated_at)
      end
    end
  end

  context "when in disabled mode" do
    before do
      Setting.work_package_done_ratio = "disabled"
    end

    it "changes progress calculation mode to work-based" do
      run_migration
      expect(Setting.find_by(name: "work_package_done_ratio")).to have_attributes(value: "field")
    end

    it "unset all % complete values and creates a journal entry for it" do
      work_packages = expect_migrates(
        from: <<~TABLE,
          subject                   | work | remaining work | % complete
          wp only pc set            |      |                |        60%
        TABLE
        to: <<~TABLE
          subject                   | work | remaining work | % complete
          wp only pc set            |      |                |
        TABLE
      )

      wp_only_pc_set = work_packages.first
      expect(wp_only_pc_set.last_journal.details).to include("done_ratio" => [60, nil])
      expect(wp_only_pc_set.last_journal.cause).to eq("type" => "system_update",
                                                      "feature" => "progress_calculation_adjusted_from_disabled_mode")
    end

    context "when all unset" do
      it "does nothing, everything is still unset and no journal is created" do
        work_packages = expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp all unset              |      |                |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp all unset              |      |                |
          TABLE
        )

        wp_all_unset = work_packages.first
        # no new journals as nothing changed
        expect(wp_all_unset.journals.count).to eq(1)
      end
    end

    context "when Work is set and Remaining work is unset" do
      it "sets Remaining work to Work, and % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp only w set             |  10h |                |
            wp both w and pc set      |  10h |                |        60%
            wp only w set 0h          |   0h |                |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp only w set             |  10h |            10h |         0%
            wp both w and pc set      |  10h |            10h |         0%
            wp only w set 0h          |   0h |             0h |
          TABLE
        )
      end
    end

    context "when Work is unset and Remaining work is set" do
      it "sets Work to Remaining work, and % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp only rw set            |      |             4h |
            wp both rw and pc set     |      |             4h |        60%
            wp only rw set 0h         |      |             0h |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp only rw set            |   4h |             4h |         0%
            wp both rw and pc set     |   4h |             4h |         0%
            wp only rw set 0h         |   0h |             0h |
          TABLE
        )
      end
    end

    context "when Work is greater than Remaining work" do
      it "derives % Complete value" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp both w and rw set      |  10h |             4h |
            wp both w and rw set 0h   |  10h |             0h |
            wp all set consistent     |  10h |             4h |        60%
            wp all set inconsistent   |  10h |             1h |        10%
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp both w and rw set      |  10h |             4h |        60%
            wp both w and rw set 0h   |  10h |             0h |       100%
            wp all set consistent     |  10h |             4h |        60%
            wp all set inconsistent   |  10h |             1h |        90%
          TABLE
        )
      end
    end

    context "when Work is equal to Remaining work" do
      it "sets % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp both w and rw set      |  10h |            10h |
            wp both w and rw set 0h   |   0h |             0h |
            wp all set inconsistent   |  10h |            10h |        60%
            wp all set inconsistent 0h|   0h |             0h |        60%
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp both w and rw set      |  10h |            10h |         0%
            wp both w and rw set 0h   |   0h |             0h |
            wp all set inconsistent   |  10h |            10h |         0%
            wp all set inconsistent 0h|   0h |             0h |
          TABLE
        )
      end
    end

    context "when Remaining work is greater than Work" do
      it "sets Remaining work to Work, and % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp both w and big rw set  |  10h |            99h |
            wp all set big wp         |  10h |            99h |        60%
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp both w and big rw set  |  10h |            10h |         0%
            wp all set big wp         |  10h |            10h |         0%
          TABLE
        )
      end
    end
  end

  ###

  context "when in work-based mode" do
    before do
      Setting.work_package_done_ratio = "field"
    end

    it "creates a journal entry for modified work packages to indicate that progress calculation was updated" do
      work_package_adjusted, work_package_not_adjusted = expect_migrates(
        from: <<~TABLE,
          subject                   | work | remaining work | % complete
          work package adjusted     |  10h |                |
          work package not adjusted |  10h |            10h |         0%
        TABLE
        to: <<~TABLE
          subject                   | work | remaining work | % complete
          work package adjusted     |  10h |            10h |         0%
          work package not adjusted |  10h |            10h |         0%
        TABLE
      )
      expect(work_package_adjusted.journals.count).to eq(2)
      expect(work_package_adjusted.last_journal.cause)
        .to eq("type" => "system_update",
               "feature" => "progress_calculation_adjusted")
      expect(work_package_not_adjusted.journals.count).to eq(1)
    end

    context "when all unset" do
      it "does nothing and everything is still unset" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp all unset              |      |                |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp all unset              |      |                |
          TABLE
        )
      end
    end

    context "when only Work is set" do
      it "sets Remaining work to Work, and % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp only w set             |  10h |                |
            wp only w set 0h          |   0h |                |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp only w set             |  10h |            10h |         0%
            wp only w set 0h          |   0h |             0h |
          TABLE
        )
      end
    end

    context "when only Remaining work is set" do
      it "sets Work to Remaining work, and % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp only rw set            |      |             4h |
            wp only rw set 0h         |      |             0h |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp only rw set            |   4h |             4h |         0%
            wp only rw set 0h         |   0h |             0h |
          TABLE
        )
      end
    end

    context "when only % Complete is set" do
      it "does nothing and % Complete is kept" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp only pc set            |      |                |        60%
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp only pc set            |      |                |        60%
          TABLE
        )
      end
    end

    context "when Work and % Complete are set, and Remaining work is unset" do
      it "derives Remaining work from Work and % Complete" do
        expect_migrates(
          from: <<~TABLE,
            subject                   |   work | remaining work | % complete
            wp w and pc set           |    10h |                |        60%
            wp w and pc set 0h        |     0h |                |         0%
            wp w and pc set 5.678h    | 5.678h |                |         0%
          TABLE
          to: <<~TABLE
            subject                   |   work | remaining work | % complete
            wp w and pc set           |    10h |             4h |        60%
            wp w and pc set 0h        |     0h |             0h |
            # no rounding if rounding remaining work would exceed work
            wp w and pc set 5.678h    | 5.678h |         5.678h |         0%
          TABLE
        )
      end
    end

    context "when Remaining work and % Complete are set, and Work is unset" do
      it "derives Work from Remaining work and % Complete" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp rw and pc set          |      |             4h |        60%
            wp rw and pc set 0%       |      |             4h |         0%
            wp rw and pc set dec      |      |             4h |        67%
            wp rw and pc set 0h       |      |             0h |         0%
            wp rw and pc set 5.678h   |      |         5.678h |         0%
          TABLE
          to: <<~TABLE
            subject                   |   work | remaining work | % complete
            wp rw and pc set          |    10h |             4h |        60%
            wp rw and pc set 0%       |     4h |             4h |         0%
            wp rw and pc set dec      | 12.12h |             4h |        67%
            wp rw and pc set 0h       |     0h |             0h |
            # no rounding when % complete is 0%
            wp rw and pc set 5.678h   | 5.678h |         5.678h |         0%
          TABLE
        )
      end
    end

    context "when Remaining work is set, % Complete is 100%, and Work is unset" do
      it "sets Work to Remaining work, sets Remaining work to 0h and keep % Complete" do
        expect_migrates(
          from: <<~TABLE,
            subject                    | work | remaining work | % complete
            wp both rw and pc set 100% |      |             4h |       100%
          TABLE
          to: <<~TABLE
            subject                    | work | remaining work | % complete
            wp both rw and pc set 100% |   4h |             0h |       100%
          TABLE
        )
      end
    end

    context "when Work is greater than Remaining work and % Complete is unset" do
      it "derives % Complete value" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp both w and rw set      |  10h |             4h |
            wp both w and rw set 0h   |  10h |             0h |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp both w and rw set      |  10h |             4h |        60%
            wp both w and rw set 0h   |  10h |             0h |       100%
          TABLE
        )
      end
    end

    context "when Work is equal to Remaining work and % Complete is unset" do
      it "sets % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp both w and rw set      |  10h |            10h |
            wp both w and rw set 0h   |   0h |             0h |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp both w and rw set     |  10h |            10h |         0%
            wp both w and rw set 0h  |   0h |             0h |
          TABLE
        )
      end
    end

    context "when Remaining work is greater than Work and % Complete is unset" do
      it "sets Remaining work to Work, and % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp both w and big rw set  |  10h |            99h |
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp both w and big rw set  |  10h |            10h |         0%
          TABLE
        )
      end
    end

    context "when Work is greater than Remaining work and % Complete is set" do
      it "derives % Complete value" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp all set consistent     |  10h |             4h |        60%
            wp all set inconsistent   |  10h |             1h |        10%
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp all set consistent     |  10h |             4h |        60%
            wp all set inconsistent   |  10h |             1h |        90%
          TABLE
        )
      end
    end

    context "when Work is equal to Remaining work and % Complete is set" do
      it "sets % Complete to 0%" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp all set consistent     |  10h |            10h |         0%
            wp all set inconsistent   |  10h |            10h |        60%
            wp all set 0h             |   0h |             0h |        55%
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp all set consistent     |  10h |            10h |         0%
            wp all set inconsistent   |  10h |            10h |         0%
            wp all set 0h             |   0h |             0h |
          TABLE
        )
      end
    end

    context "when Remaining work is greater than Work and % Complete is set" do
      it "computes Remaining work from Work and % Complete" do
        expect_migrates(
          from: <<~TABLE,
            subject                   | work | remaining work | % complete
            wp all set big wp         |  10h |            99h |        60%
            wp all set big wp round   |   8h |           2.4h |        70%
          TABLE
          to: <<~TABLE
            subject                   | work | remaining work | % complete
            wp all set big wp         |  10h |             4h |        60%
            # would be 2.4000000000000004h without rounding
            wp all set big wp round   |   8h |           2.4h |        70%
          TABLE
        )
      end
    end
  end

  ###

  context "when in status mode" do
    shared_let(:status_0p_todo) { create(:status, name: "To do (0%)", default_done_ratio: 0) }
    shared_let(:status_30p_doing) { create(:status, name: "Doing (30%)", default_done_ratio: 30) }
    shared_let(:status_100p_done) { create(:status, name: "Done (100%)", default_done_ratio: 100) }

    before do
      Setting.work_package_done_ratio = "status"
    end

    it "creates a journal entry for modified work packages to indicate that progress calculation was updated" do
      wp_adjusted, wp_not_adjusted = expect_migrates(
        from: <<~TABLE,
          subject         | status      | work | remaining work | % complete
          wp adjusted     | Done (100%) |  10h |                |
          wp not adjusted | Done (100%) |  10h |             0h |       100%
        TABLE
        to: <<~TABLE
          subject         | status      | work | remaining work | % complete
          wp adjusted     | Done (100%) |  10h |             0h |       100%
          wp not adjusted | Done (100%) |  10h |             0h |       100%
        TABLE
      )
      expect(wp_adjusted.journals.count).to eq(2)
      expect(wp_adjusted.last_journal.cause)
        .to eq("type" => "system_update",
               "feature" => "progress_calculation_adjusted")
      expect(wp_not_adjusted.journals.count).to eq(1)
    end

    context "when only % Complete is set, and is the same as its status" do
      it "does nothing, the % Complete value is kept, work and remaining work are kept unset, and no journal is created" do
        work_packages = expect_migrates(
          from: <<~TABLE,
            subject     | status      | work | remaining work | % complete
            wp 0%       | To do (0%)  |      |                |         0%
            wp 30%      | Doing (30%) |      |                |        30%
            wp 100%     | Done (100%) |      |                |       100%
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete
            wp 0%       | To do (0%)  |      |                |         0%
            wp 30%      | Doing (30%) |      |                |        30%
            wp 100%     | Done (100%) |      |                |       100%
          TABLE
        )

        work_packages.each do |wp|
          # no new journals as nothing changed
          expect(wp.journals.count).to eq(1)
        end
      end
    end

    context "when % Complete is different from its status value (set or unset)" do
      it "updates % Complete value to the status value, and a journal entry is created" do
        work_packages = expect_migrates(
          from: <<~TABLE,
            subject     | status      | work | remaining work | % complete
            wp          | Doing (30%) |      |                |
            wp 0%       | To do (0%)  |      |                |        55%
            wp 30%      | Doing (30%) |      |                |        55%
            wp 100%     | Done (100%) |      |                |        55%
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete
            wp          | Doing (30%) |      |                |        30%
            wp 0%       | To do (0%)  |      |                |         0%
            wp 30%      | Doing (30%) |      |                |        30%
            wp 100%     | Done (100%) |      |                |       100%
          TABLE
        )

        wp = work_packages.first
        # one new journal as % complete was changed
        expect(wp.journals.count).to eq(2)
      end
    end

    context "when only Work is set" do
      it "sets % Complete value to the status value, and derives Remaining work" do
        expect_migrates(
          from: <<~TABLE,
            subject     | status      | work    | remaining work | % complete
            wp w 0%     | To do (0%)  |  10h    |                |
            wp w 0% dec | To do (0%)  |  5.678h |                |
            wp w 30%    | Doing (30%) |  10h    |                |
            wp w 100%   | Done (100%) |  10h    |                |
            wp w 0% 0h  | To do (0%)  |   0h    |                |
            wp w 100% 0h| Done (100%) |   0h    |                |
          TABLE
          to: <<~TABLE
            subject     | status      | work    | remaining work | % complete
            wp w 0%     | To do (0%)  |  10h    |            10h |         0%
            wp w 0% dec | To do (0%)  |  5.678h |         5.678h |         0%
            wp w 30%    | Doing (30%) |  10h    |             7h |        30%
            wp w 100%   | Done (100%) |  10h    |             0h |       100%
            wp w 0% 0h  | To do (0%)  |   0h    |             0h |         0%
            wp w 100% 0h| Done (100%) |   0h    |             0h |       100%
          TABLE
        )
      end
    end

    context "when only Remaining work is set" do
      it "sets % Complete value to the status value, and derives Work" do
        expect_migrates(
          from: <<~TABLE,
            subject     | status      | work | remaining work | % complete
            rw 0%       | To do (0%)  |      |            10h |
            rw 30%      | Doing (30%) |      |             7h |
            rw 100% 5h  | Done (100%) |      |             5h |
            rw 0% 0h    | To do (0%)  |      |             0h |
            rw 100% 0h  | Done (100%) |      |             0h |
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete
            rw 0%       | To do (0%)  |  10h |            10h |         0%
            rw 30%      | Doing (30%) |  10h |             7h |        30%
            rw 100% 5h  | Done (100%) |   5h |             0h |       100%
            rw 0% 0h    | To do (0%)  |   0h |             0h |         0%
            rw 100% 0h  | Done (100%) |   0h |             0h |       100%
          TABLE
        )
      end
    end

    context "when both Work and Remaining work are set" do
      it "sets % Complete value to the status value, and derives Remaining work" do
        expect_migrates(
          from: <<~TABLE,
            subject     | status      | work | remaining work | % complete
            rw 0%       | To do (0%)  |  10h |            10h |
            rw 30% 0h   | Doing (30%) |  10h |             0h |
            rw 30% 99h  | Doing (30%) |  10h |            99h |
            rw 30% 5h   | Doing (30%) |  10h |             5h |
            rw 30% 10h  | Doing (30%) |  10h |            10h |
            rw 100%     | Done (100%) |  10h |             0h |
            rw 0% 0h    | To do (0%)  |   0h |             0h |
            rw 100% 0h  | Done (100%) |   0h |             0h |
          TABLE
          to: <<~TABLE
            subject     | status      | work | remaining work | % complete
            rw 0%       | To do (0%)  |  10h |            10h |         0%
            rw 30% 0h   | Doing (30%) |  10h |             7h |        30%
            rw 30% 99h  | Doing (30%) |  10h |             7h |        30%
            rw 30% 5h   | Doing (30%) |  10h |             7h |        30%
            rw 30% 10h  | Doing (30%) |  10h |             7h |        30%
            rw 100%     | Done (100%) |  10h |             0h |       100%
            rw 0% 0h    | To do (0%)  |   0h |             0h |         0%
            rw 100% 0h  | Done (100%) |   0h |             0h |       100%
          TABLE
        )
      end
    end

    context "when parent is open without any work or remaining work set, " \
            "and children have a 100% complete status" do
      it "sets parent total % complete to 100%" do
        expect_migrates(
          from: <<~TABLE,
            hierarchy    | status      | work | remaining work | % complete
            parent       | To do (0%)  |      |                |         0%
              child1     | Done (100%) |  10h |             0h |       100%
              child2     | Done (100%) |  10h |             0h |       100%
          TABLE
          to: <<~TABLE
            hierarchy    | status      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent       | To do (0%)  |      |                |         0% |    20h |               0h |         100%
              child1     | Done (100%) |  10h |             0h |       100% |        |                  |
              child2     | Done (100%) |  10h |             0h |       100% |        |                  |
          TABLE
        )
      end
    end
  end

  describe "totals computation" do
    context "when totals are not up-to-date" do
      # rubocop:disable RSpec/ExampleLength
      it "computes them" do
        expect_migrates(
          from: <<~TABLE,
            hierarchy    | work | remaining work | ∑ work | ∑ remaining work | ∑ % complete
            grandparent  |  10h |             1h |
              parent 1   |  10h |             2h |
                child 11 |  10h |             3h |
                child 12 |  10h |             4h |
                child 13 |  10h |             5h |
              parent 2   |  10h |             6h |
                child 21 |  10h |             7h |
                child 22 |  10h |             8h |
                child 23 |  10h |             9h |
                child 24 |  10h |            10h |
          TABLE
          to: <<~TABLE
            subject      | work | remaining work | ∑ work | ∑ remaining work | ∑ % complete
            grandparent  |  10h |             1h |   100h |              55h |          45%
              parent 1   |  10h |             2h |    40h |              14h |          65%
                child 11 |  10h |             3h |        |                  |
                child 12 |  10h |             4h |        |                  |
                child 13 |  10h |             5h |        |                  |
              parent 2   |  10h |             6h |    50h |              40h |          20%
                child 21 |  10h |             7h |        |                  |
                child 22 |  10h |             8h |        |                  |
                child 23 |  10h |             9h |        |                  |
                child 24 |  10h |            10h |        |                  |
          TABLE
        )
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context "when total work and total remaining work are 0h" do
      it "unset total % complete" do
        expect_migrates(
          from: <<~TABLE,
            hierarchy    | work | remaining work |
            parent       |   0h |             0h |
              child      |   0h |             0h |
          TABLE
          to: <<~TABLE
            subject      | work | remaining work | ∑ work | ∑ remaining work | ∑ % complete
            parent       |   0h |             0h |     0h |               0h |
              child      |   0h |             0h |        |                  |
          TABLE
        )
      end
    end

    context "when parent does not have any work or remaining work set, " \
            "and children have a 100% complete status" do
      it "sets parent total % complete to 100%" do
        expect_migrates(
          from: <<~TABLE,
            hierarchy    | work | remaining work | % complete
            parent       |      |                |
              child1     |  10h |             0h |       100%
              child2     |  10h |             0h |       100%
          TABLE
          to: <<~TABLE
            hierarchy    | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            parent       |      |                |            |    20h |               0h |         100%
              child1     |  10h |             0h |       100% |        |                  |
              child2     |  10h |             0h |       100% |        |                  |
          TABLE
        )
      end
    end

    context "when work and remaining work are unset" do
      it "does not set total work, total remaining work, and total % complete" do
        expect_migrates(
          from: <<~TABLE,
            subject      | work | remaining work | % complete
            wp all unset |      |                |
            wp 0%        |      |                |         0%
            wp 30%       |      |                |        30%
            wp 100%      |      |                |       100%
          TABLE
          to: <<~TABLE
            subject      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
            wp all unset |      |                |            |        |                  |
            wp 0%        |      |                |         0% |        |                  |
            wp 30%       |      |                |        30% |        |                  |
            wp 100%      |      |                |       100% |        |                  |
          TABLE
        )
      end
    end

    context "when ∑ % complete has had some values (including wrong ones)" do
      let_work_packages(<<~TABLE)
        hierarchy          | work  | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete |
        wp zero            |       |                |          0 |        |                  |            0 |
        wp correct         |  100h |            50h |         50 |   100h |             50h  |           50 |
          wp correct child |       |                |            |        |                  |              |
        wp wrong           |       |                |         90 |   100h |             50h  |           90 |
          wp wrong child   |  100h |            50h |         20 |    10h |             10h  |           20 |
      TABLE

      before do
        run_migration
      end

      it "fixes the total values and sets ∑ % complete to nil (not 0) but keeps % complete (unless wrong)" do
        expect_work_packages(table_work_packages.map(&:reload), <<~TABLE)
          subject            | work  | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete |
          wp zero            |       |                |          0 |        |                  |              |
          wp correct         |  100h |            50h |         50 |   100h |              50h |           50 |
            wp correct child |       |                |            |        |                  |              |
          wp wrong           |       |                |         90 |   100h |              50h |           50 |
            wp wrong child   |  100h |            50h |         50 |        |                  |              |
        TABLE
      end

      it "reworks the pre migration journals to unset ∑ % complete" do
        pre_journals = table_work_packages
          .map(&:reload)
          .flat_map { |wp| wp.journals[...-1] } # remove the last journal

        pre_journals.each do |journal|
          expect(journal.get_changes.keys).not_to include("derived_done_ratio")
        end
      end

      it "creates no journals for work packages transitioning only ∑ % complete from 0 to nil" do
        expect(wp_zero.journals.count).to eq(1)
      end

      it "creates a journal for the correct work package as the old ∑ % complete value has been set to null during the job" do
        expect(wp_correct.journals.count).to eq(2)

        expect(wp_correct.journals.first.get_changes.keys)
          .not_to include("derived_done_ratio")

        expect(wp_correct.journals.last.get_changes["derived_done_ratio"])
          .to eql [nil, 50]
      end

      it "creates a journal for the work package transitioning ∑ % complete from 90 to 50" do
        expect(wp_wrong.journals.count).to eq(2)

        expect(wp_wrong.journals.first.get_changes.keys)
          .not_to include("derived_done_ratio")

        expect(wp_wrong.journals.last.get_changes["derived_done_ratio"])
          .to eql [nil, 50]
      end
    end
  end

  describe "error during job execution" do
    let_work_packages(<<~TABLE)
      subject     | work | remaining work | % complete
      wp working  |      |             4h |        60%
      wp breaking |      |             4h |        60%
    TABLE

    before do
      Setting.work_package_done_ratio = "field"

      allow(Journals::CreateService)
        .to receive(:new)
              .with(wp_working, User.system)
              .and_call_original

      allow(Journals::CreateService)
              .to receive(:new)
                    .with(wp_breaking, User.system)
                    .and_return(nil)

      ActiveRecord::Migration.suppress_messages { described_class.new.up }

      begin
        perform_enqueued_jobs
      rescue StandardError
      end
    end

    it "does not create a journal entry" do
      table_work_packages.each do |wp|
        expect(wp.journals.count).to eq(1)
      end
    end

    it "does not update the work packages" do
      expect_work_packages(WorkPackage.all, <<~TABLE)
        subject     | work | remaining work | % complete
        wp working  |      |             4h |        60%
        wp breaking |      |             4h |        60%
      TABLE
    end
  end
end

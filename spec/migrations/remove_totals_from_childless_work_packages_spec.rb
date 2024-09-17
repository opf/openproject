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
require Rails.root.join("db/migrate/20240506091102_remove_totals_from_childless_work_packages.rb")

RSpec.describe RemoveTotalsFromChildlessWorkPackages, type: :model do
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
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status_new)
  end

  describe "journal creation" do
    before do
      Setting.work_package_done_ratio = "field"
    end

    context "when the migration is run" do
      let_work_packages(<<~TABLE)
        hierarchy               | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
        wp totals set           |   5h |             3h |        40% |     5h |              3h  |          40%
        wp only pc set          |      |                |        60% |        |                  |
        wp parent consistent    |  10h |             4h |        60% |    20h |               8h |          60%
          wp all set consistent |  10h |             4h |        60% |        |                  |
          wp child totals set   |   0h |             0h |            |     0h |               0h |
      TABLE

      before do
        run_migration
      end

      it "removes totals from childless work packages" do
        expect_work_packages(table_work_packages.map(&:reload), <<~TABLE)
          hierarchy               | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          wp totals set           |   5h |             3h |        40% |        |                  |
          wp only pc set          |      |                |        60% |        |                  |
          wp parent consistent    |  10h |             4h |        60% |    20h |               8h |          60%
            wp all set consistent |  10h |             4h |        60% |        |                  |
            wp child totals set   |   0h |             0h |            |        |                  |
        TABLE
      end

      it "creates a journal entry only for each altered work package" do
        expected_altered_work_packages = [wp_totals_set, wp_child_totals_set]
        expected_altered_work_packages.each do |work_package|
          expect(work_package.journals.count).to eq 2
          last_journal = work_package.last_journal
          expect(last_journal.user).to eq(User.system)
          expect(last_journal.cause_type).to eq("system_update")
          expect(last_journal.cause_feature).to eq("totals_removed_from_childless_work_packages")
        end

        expected_non_altered_work_packages = table_work_packages - expected_altered_work_packages
        expected_non_altered_work_packages.each do |work_package|
          expect(work_package.journals.count).to eq 1
        end
      end
    end
  end
end

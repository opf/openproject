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

RSpec.describe WorkPackages::Progress::MigrateRemoveTotalsFromChildlessWorkPackagesJob do
  shared_let(:user) { create(:user) }
  shared_let(:priority) { create(:priority, name: "Normal") }
  shared_let(:project) { create(:project, name: "Main project") }
  shared_let(:status_new) { create(:status, name: "New") }

  before_all do
    set_factory_default(:user, user)
    set_factory_default(:priority, priority)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status_new)
  end

  subject(:job) { described_class }

  def expect_performing_job_changes(from:, to:)
    table = create_table(from)
    job.perform_now
    expect_work_packages(table.work_packages.map(&:reload), to)
    table.work_packages
  end

  context "when some work packages without children have total work, total remaining work or total % complete set" do
    it "unsets totals and create a journal entry" do
      work_packages = expect_performing_job_changes(
        from: <<~TABLE,
          subject     | ∑ work | ∑ remaining work | ∑ % complete
          wp tw set   |     5h |                  |
          wp trw set  |        |               2h |
          wp tpc set  |        |                  |          60%
          wp tall set |     5h |               2h |          60%
        TABLE
        to: <<~TABLE
          subject     | ∑ work | ∑ remaining work | ∑ % complete
          wp tw set   |        |                  |
          wp trw set  |        |                  |
          wp tpc set  |        |                  |
          wp tall set |        |                  |
        TABLE
      )
      work_packages.each do |work_package|
        expect(work_package.journals.count).to eq 2
        last_journal = work_package.last_journal
        expect(last_journal.user).to eq(User.system)
        expect(last_journal.cause_type).to eq("system_update")
        expect(last_journal.cause_feature).to eq("totals_removed_from_childless_work_packages")
      end
    end
  end

  context "when some work packages without children have all totals unset" do
    it "does not update them and does not create any new journal entries" do
      work_packages = expect_performing_job_changes(
        from: <<~TABLE,
          subject      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          work package |  10h |             7h |        30% |        |                  |
          wp blank     |      |                |            |        |                  |
        TABLE
        to: <<~TABLE
          subject      | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          work package |  10h |             7h |        30% |        |                  |
          wp blank     |      |                |            |        |                  |
        TABLE
      )
      work_packages.each do |work_package|
        expect(work_package.journals.count).to eq 1
      end
    end
  end

  context "when some parent work packages have total work, total remaining work or total % complete set" do
    # rubocop:disable RSpec/ExampleLength
    it "does not update them and does not create any new journal entries" do
      work_packages = expect_performing_job_changes(
        from: <<~TABLE,
          hierarchy   | ∑ work | ∑ remaining work | ∑ % complete
          wp tw set   |     5h |                  |
            child1    |        |                  |
          wp trw set  |        |               2h |
            child2    |        |                  |
          wp tpc set  |        |                  |          60%
            child3    |        |                  |
          wp tall set |     5h |               2h |          60%
            child4    |        |                  |
        TABLE
        to: <<~TABLE
          subject     | ∑ work | ∑ remaining work | ∑ % complete
          wp tw set   |     5h |                  |
            child1    |        |                  |
          wp trw set  |        |               2h |
            child2    |        |                  |
          wp tpc set  |        |                  |          60%
            child3    |        |                  |
          wp tall set |     5h |               2h |          60%
            child4    |        |                  |
        TABLE
      )
      work_packages.each do |work_package|
        expect(work_package.journals.count).to eq 1
      end
    end
    # rubocop:enable RSpec/ExampleLength

    it "does not even try to recompute totals for parent work packages (not that job's business)" do
      expect_performing_job_changes(
        from: <<~TABLE,
          hierarchy   | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          parent      |      |                |            |        |                  |
            child     |  10h |             7h |        30% |        |                  |
        TABLE
        to: <<~TABLE
          subject     | work | remaining work | % complete | ∑ work | ∑ remaining work | ∑ % complete
          parent      |      |                |            |        |                  |
            child     |  10h |             7h |        30% |        |                  |
        TABLE
      )
    end
  end
end

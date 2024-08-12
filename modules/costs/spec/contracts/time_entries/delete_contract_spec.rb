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

RSpec.describe TimeEntries::DeleteContract do
  let(:current_user) { build_stubbed(:user) }
  let(:other_user) { build_stubbed(:user) }
  let(:time_entry_work_package) { build_stubbed(:work_package, project: time_entry_project) }
  let(:time_entry_project) { build_stubbed(:project) }
  let(:time_entry_user) { current_user }
  let(:time_entry_activity) { build_stubbed(:time_entry_activity) }
  let(:time_entry_spent_on) { Date.today }
  let(:time_entry_hours) { 5 }
  let(:time_entry_ongoing) { false }
  let(:time_entry_comments) { "A comment" }
  let(:work_package_visible) { true }
  let(:permissions) { %i[edit_time_entries] }
  let(:time_entry) do
    build_stubbed(:time_entry,
                  project: time_entry_project,
                  work_package: time_entry_work_package,
                  user: time_entry_user,
                  ongoing: time_entry_ongoing,
                  activity: time_entry_activity,
                  spent_on: time_entry_spent_on,
                  hours: time_entry_hours,
                  comments: time_entry_comments)
  end

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project *permissions, project: time_entry_project
    end

    allow(time_entry_work_package)
          .to receive(:visible?)
          .with(current_user)
          .and_return(work_package_visible)
  end

  subject(:contract) { described_class.new(time_entry, current_user) }

  def expect_valid(valid, symbols = {})
    expect(contract.validate).to eq(valid)

    symbols.each do |key, arr|
      expect(contract.errors.symbols_for(key)).to match_array arr
    end
  end

  shared_examples "is valid" do
    it "is valid" do
      expect_valid(true)
    end
  end

  it_behaves_like "is valid"

  context "when user is not allowed to delete time entries" do
    let(:permissions) { [] }

    it "is invalid" do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end

  context "when time entry ongoing and user as log_time permission" do
    let(:time_entry_ongoing) { true }
    let(:permissions) { %i[log_own_time] }

    it_behaves_like "is valid"
  end

  context "when time entry not ongoing and user as log_time permission" do
    let(:time_entry_ongoing) { false }
    let(:permissions) { %i[log_own_time] }

    it "is invalid" do
      expect_valid(false, base: %i(error_unauthorized))
    end
  end

  context "when time_entry user is not contract user" do
    let(:time_entry_user) { other_user }

    context "when has permission" do
      let(:permissions) { %i[edit_time_entries] }

      it "is valid" do
        expect_valid(true)
      end
    end

    context "when has no permission" do
      let(:permissions) { %i[edit_own_time_entries] }

      it "is invalid" do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end
  end
end

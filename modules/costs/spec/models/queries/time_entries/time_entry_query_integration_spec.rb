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

RSpec.describe Queries::TimeEntries::TimeEntryQuery, "integration" do
  let(:instance) { described_class.new(user:) }

  before do
    login_as(user)
  end

  context "when using ongoing filter" do
    let(:project) { create(:project, enabled_module_names: %w[costs]) }
    let(:user) { create(:user, member_with_permissions: { project => %i[log_own_time] }) }
    let(:work_package) { create(:work_package, project:) }
    let(:other_user) { create(:user, member_with_permissions: { project => %i[log_own_time] }) }
    let(:other_work_package) { create(:work_package, project:) }

    let!(:user_timer) { create(:time_entry, user:, work_package:, ongoing: true) }
    let!(:other_user_timer) { create(:time_entry, user: other_user, work_package: other_work_package, ongoing: true) }

    describe "#results" do
      subject { instance.results }

      before do
        instance.where("ongoing", "=", ["t"])
      end

      it "only returns the users own time entries" do
        expect(subject).to contain_exactly(user_timer)
      end

      context "when user has log_time permission" do
        let(:user) { create(:user, member_with_permissions: { project => %i[log_time] }) }

        it "still returns the users own time entries" do
          expect(subject).to contain_exactly(user_timer)
        end
      end
    end
  end
end

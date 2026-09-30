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

require_relative "../spec_helper"

RSpec.describe DefaultHourlyRate do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:rate) do
    build(:default_hourly_rate, project:,
                                user:)
  end

  describe "#user" do
    describe "WHEN an existing user is provided" do
      before do
        rate.user = user
        rate.save!
      end

      it { expect(rate.user).to eq(user) }
    end

    describe "WHEN a non existing user is provided (i.e. the user is deleted)" do
      before do
        rate.user = user
        rate.save!
        user.destroy
        rate.reload
      end

      it { expect(rate.user).to eq(DeletedUser.first) }
    end
  end

  describe "recosting time entries on update" do
    shared_let(:rated_user) { create(:user) }
    shared_let(:rated_project) { create(:project, member_with_permissions: { rated_user => %i[log_time] }) }
    shared_let(:work_package) { create(:work_package, project: rated_project) }

    let!(:entry_before) do
      create(:time_entry, user: rated_user, project: rated_project, entity: work_package,
                          hours: 1, spent_on: Date.new(2024, 6, 1))
    end
    let!(:entry_after) do
      create(:time_entry, user: rated_user, project: rated_project, entity: work_package,
                          hours: 1, spent_on: Date.new(2025, 6, 1))
    end
    let!(:default_rate) do
      create(:default_hourly_rate, user: rated_user, rate: 100, valid_from: Date.new(2025, 1, 1))
    end

    it "costs only the entries the rate is in effect for" do
      expect(entry_before.reload.costs).to eq(0)
      expect(entry_after.reload.costs).to eq(100)
    end

    it "recosts entries newly covered by a backdated valid_from" do
      default_rate.update!(valid_from: Date.new(2024, 1, 1))

      expect(entry_before.reload.costs).to eq(100)
    end

    it "recosts covered entries when only the rate value changes" do
      default_rate.update!(rate: 120)

      expect(entry_after.reload.costs).to eq(120)
    end
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe User, '#destroy', type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:substitute_user) { DeletedUser.first }
  let(:project) { FactoryBot.create(:valid_project) }

  before do
    user
    user2
  end

  after do
    User.current = nil
  end

  describe 'WHEN the user has a labor_budget_item associated' do
    let(:item) { FactoryBot.build(:labor_budget_item, user: user) }

    before do
      item.save!

      Principals::DeleteJob.perform_now(user)
    end

    it { expect(LaborBudgetItem.find_by_id(item.id)).to eq(item) }
    it { expect(item.user_id).to eq(user.id) }
  end

  describe 'WHEN the user has a cost entry' do
    let(:work_package) { FactoryBot.create(:work_package) }
    let(:entry) do
      FactoryBot.create(:cost_entry, user: user,
                                     project: work_package.project,
                                     units: 100.0,
                                     spent_on: Date.today,
                                     work_package: work_package,
                                     comments: '')
    end

    before do
      FactoryBot.create(:member, project: work_package.project,
                                 user: user,
                                 roles: [FactoryBot.build(:role)])
      entry

      Principals::DeleteJob.perform_now(user)

      entry.reload
    end

    it { expect(entry.user_id).to eq(user.id) }
  end

  describe 'WHEN the user is assigned an hourly rate' do
    let(:hourly_rate) do
      FactoryBot.build(:hourly_rate, user: user,
                                     project: project)
    end

    before do
      hourly_rate.save!
      Principals::DeleteJob.perform_now(user)
    end

    it { expect(HourlyRate.find_by_id(hourly_rate.id)).to eq(hourly_rate) }
    it { expect(hourly_rate.reload.user_id).to eq(user.id) }
  end

  describe 'WHEN the user is assigned a default hourly rate' do
    let(:default_hourly_rate) do
      FactoryBot.build(:default_hourly_rate, user: user,
                                             project: project)
    end

    before do
      default_hourly_rate.save!
      Principals::DeleteJob.perform_now(user)
    end

    it { expect(DefaultHourlyRate.find_by_id(default_hourly_rate.id)).to eq(default_hourly_rate) }
    it { expect(default_hourly_rate.reload.user_id).to eq(user.id) }
  end
end

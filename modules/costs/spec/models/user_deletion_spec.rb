#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

  shared_examples_for 'costs updated journalized associated object' do
    before do
      User.current = user2
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user2)
      end
      associated_instance.save!

      User.current = user # in order to have the content journal created by the user
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by_id(associated_instance.id)).to eq(associated_instance) }
    it 'should replace the user on all associations' do
      associations.each do |association|
        expect(associated_instance.send(association)).to eq(substitute_user)
      end
    end
    it { expect(associated_instance.journals.first.user).to eq(user2) }
    it 'should update first journal details' do
      associations.each do |association|
        expect(associated_instance.journals.first.details["#{association}_id".to_sym].last).to eq(user2.id)
      end
    end
    it { expect(associated_instance.journals.last.user).to eq(substitute_user) }
    it 'should update second journal details' do
      associations.each do |association|
        expect(associated_instance.journals.last.details["#{association}_id".to_sym].last).to eq(substitute_user.id)
      end
    end
  end

  shared_examples_for 'costs created journalized associated object' do
    before do
      User.current = user # in order to have the content journal created by the user
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user)
      end
      associated_instance.save!

      User.current = user2
      associated_instance.reload
      associations.each do |association|
        associated_instance.send(association.to_s + '=', user2)
      end
      associated_instance.save!

      user.destroy
      associated_instance.reload
    end

    it { expect(associated_class.find_by_id(associated_instance.id)).to eq(associated_instance) }
    it 'should keep the current user on all associations' do
      associations.each do |association|
        expect(associated_instance.send(association)).to eq(user2)
      end
    end
    it { expect(associated_instance.journals.first.user).to eq(substitute_user) }
    it 'should update the first journal' do
      associations.each do |association|
        expect(associated_instance.journals.first.details["#{association}_id".to_sym].last).to eq(substitute_user.id)
      end
    end
    it { expect(associated_instance.journals.last.user).to eq(user2) }
    it 'should update the last journal' do
      associations.each do |association|
        expect(associated_instance.journals.last.details["#{association}_id".to_sym].first).to eq(substitute_user.id)
        expect(associated_instance.journals.last.details["#{association}_id".to_sym].last).to eq(user2.id)
      end
    end
  end

  describe 'WHEN the user updated a cost object' do
    let(:associations) { [:author] }
    let(:associated_instance) { FactoryBot.build(:variable_cost_object) }
    let(:associated_class) { CostObject }

    it_should_behave_like 'costs updated journalized associated object'
  end

  describe 'WHEN the user created a cost object' do
    let(:associations) { [:author] }
    let(:associated_instance) { FactoryBot.build(:variable_cost_object) }
    let(:associated_class) { CostObject }

    it_should_behave_like 'costs created journalized associated object'
  end

  describe 'WHEN the user has a labor_budget_item associated' do
    let(:item) { FactoryBot.build(:labor_budget_item, user: user) }

    before do
      item.save!

      user.destroy
    end

    it { expect(LaborBudgetItem.find_by_id(item.id)).to eq(item) }
    it { expect(item.user_id).to eq(user.id) }
  end

  describe 'WHEN the user has a cost entry' do
    let(:work_package) { FactoryBot.create(:work_package) }
    let(:entry) {
      FactoryBot.create(:cost_entry, user: user,
                                     project: work_package.project,
                                     units: 100.0,
                                     spent_on: Date.today,
                                     work_package: work_package,
                                     comments: '')
    }

    before do
      FactoryBot.create(:member, project: work_package.project,
                                  user: user,
                                  roles: [FactoryBot.build(:role)])
      entry

      user.destroy

      entry.reload
    end

    it { expect(entry.user_id).to eq(user.id) }
  end

  describe 'WHEN the user is assigned an hourly rate' do
    let(:hourly_rate) {
      FactoryBot.build(:hourly_rate, user: user,
                                      project: project)
    }

    before do
      hourly_rate.save!
      user.destroy
    end

    it { expect(HourlyRate.find_by_id(hourly_rate.id)).to eq(hourly_rate) }
    it { expect(hourly_rate.reload.user_id).to eq(user.id) }
  end

  describe 'WHEN the user is assigned a default hourly rate' do
    let(:default_hourly_rate) {
      FactoryBot.build(:default_hourly_rate, user: user,
                                              project: project)
    }

    before do
      default_hourly_rate.save!
      user.destroy
    end

    it { expect(DefaultHourlyRate.find_by_id(default_hourly_rate.id)).to eq(default_hourly_rate) }
    it { expect(default_hourly_rate.reload.user_id).to eq(user.id) }
  end
end

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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TimeEntry, type: :model do
  include Cost::PluginSpecHelper
  let(:project) { FactoryBot.create(:project_with_types, public: false) }
  let(:project2) { FactoryBot.create(:project_with_types, public: false) }
  let(:work_package) {
    FactoryBot.create(:work_package, project: project,
                                      type: project.types.first,
                                      author: user)
  }
  let(:work_package2) {
    FactoryBot.create(:work_package, project: project2,
                                      type: project2.types.first,
                                      author: user2)
  }
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:date) { Date.today }
  let(:rate) { FactoryBot.build(:cost_rate) }
  let!(:hourly_one) { FactoryBot.create(:hourly_rate, valid_from: 2.days.ago, project: project, user: user) }
  let!(:hourly_three) { FactoryBot.create(:hourly_rate, valid_from: 4.days.ago, project: project, user: user) }
  let!(:hourly_five) { FactoryBot.create(:hourly_rate, valid_from: 6.days.ago, project: project, user: user) }
  let!(:default_hourly_one) { FactoryBot.create(:default_hourly_rate, valid_from: 2.days.ago, project: project, user: user2) }
  let!(:default_hourly_three) { FactoryBot.create(:default_hourly_rate, valid_from: 4.days.ago, project: project, user: user2) }
  let!(:default_hourly_five) { FactoryBot.create(:default_hourly_rate, valid_from: 6.days.ago, project: project, user: user2) }
  let(:hours) { 5.0 }
  let(:time_entry) do
    FactoryBot.create(:time_entry, project: project,
                                    work_package: work_package,
                                    spent_on: date,
                                    hours: hours,
                                    user: user,
                                    rate: hourly_one,
                                    comments: 'lorem')
  end

  let(:time_entry2) do
    FactoryBot.create(:time_entry, project: project,
                                    work_package: work_package,
                                    spent_on: date,
                                    hours: hours,
                                    user: user,
                                    rate: hourly_one,
                                    comments: 'lorem')
  end

  it 'should always prefer overridden_costs' do
    allow(User).to receive(:current).and_return(user)

    value = rand(500)
    time_entry.overridden_costs = value
    expect(time_entry.overridden_costs).to eq(value)
    expect(time_entry.real_costs).to eq(value)
    time_entry.save!
  end

  describe 'given rate' do
    before(:each) do
      allow(User).to receive(:current).and_return(user)
      @default_example = time_entry2
    end

    it 'should return the current costs depending on the number of hours' do
      (0..100).each do |hours|
        time_entry.hours = hours
        time_entry.save!
        expect(time_entry.costs).to eq(time_entry.rate.rate * hours)
      end
    end

    it 'should update cost if a new rate is added at the end' do
      time_entry.user = User.current
      time_entry.spent_on = Time.now
      time_entry.hours = 1
      time_entry.save!
      expect(time_entry.costs).to eq(hourly_one.rate)
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 1.day.ago
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = hourly_one.project
      end).save!
      time_entry.reload
      expect(time_entry.rate).not_to eq(hourly_one)
      expect(time_entry.costs).to eq(hourly.rate)
    end

    it 'should update cost if a new rate is added in between' do
      time_entry.user = User.current
      time_entry.spent_on = 3.days.ago.to_date
      time_entry.hours = 1
      time_entry.save!
      expect(time_entry.costs).to eq(hourly_three.rate)
      (hourly = HourlyRate.new.tap do |hr|
        hr.valid_from = 3.days.ago.to_date
        hr.rate       = 1.0
        hr.user       = User.current
        hr.project    = hourly_one.project
      end).save!
      time_entry.reload
      expect(time_entry.rate).not_to eq(hourly_three)
      expect(time_entry.costs).to eq(hourly.rate)
    end

    it 'should update cost if a spent_on changes' do
      time_entry.hours = 1
      (5.days.ago.to_date..Date.today).each do |time|
        time_entry.spent_on = time.to_date
        time_entry.save!
        expect(time_entry.costs).to eq(time_entry.user.rate_at(time, project.id).rate)
      end
    end

    it 'should update cost if a rate is removed' do
      time_entry.spent_on = hourly_one.valid_from
      time_entry.hours = 1
      time_entry.save!
      expect(time_entry.costs).to eq(hourly_one.rate)
      hourly_one.destroy
      time_entry.reload
      expect(time_entry.costs).to eq(hourly_three.rate)
      hourly_three.destroy
      time_entry.reload
      expect(time_entry.costs).to eq(hourly_five.rate)
    end

    it 'should be able to change order of rates (sorted by valid_from)' do
      time_entry.spent_on = hourly_one.valid_from
      time_entry.save!
      expect(time_entry.rate).to eq(hourly_one)
      hourly_one.valid_from = hourly_three.valid_from - 1.day
      hourly_one.save!
      time_entry.reload
      expect(time_entry.rate).to eq(hourly_three)
    end
  end

  describe 'default rate' do
    before(:each) do
      allow(User).to receive(:current).and_return(user)
      @default_example = time_entry2
    end

    it 'should return the current costs depending on the number of hours' do
      (0..100).each do |hours|
        @default_example.hours = hours
        @default_example.save!
        expect(@default_example.costs).to eq(@default_example.rate.rate * hours)
      end
    end

    it 'should update cost if a new rate is added at the end' do
      @default_example.user = user2
      @default_example.spent_on = Time.now.to_date
      @default_example.hours = 1
      @default_example.save!
      expect(@default_example.costs).to eq(default_hourly_one.rate)
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 1.day.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = user2
      end).save!
      @default_example.reload
      expect(@default_example.rate).not_to eq(default_hourly_one)
      expect(@default_example.costs).to eq(hourly.rate)
    end

    it 'should update cost if a new rate is added in between' do
      @default_example.user = user2
      @default_example.spent_on = 3.days.ago.to_date
      @default_example.hours = 1
      @default_example.save!
      expect(@default_example.costs).to eq(default_hourly_three.rate)
      (hourly = DefaultHourlyRate.new.tap do |dhr|
        dhr.valid_from = 3.days.ago.to_date
        dhr.rate       = 1.0
        dhr.user       = user2
      end).save!
      @default_example.reload
      expect(@default_example.rate).not_to eq(default_hourly_three)
      expect(@default_example.costs).to eq(hourly.rate)
    end

    it 'should update cost if a spent_on changes' do
      @default_example.hours = 1
      (5.days.ago.to_date..Date.today).each do |time|
        @default_example.spent_on = time.to_date
        @default_example.save!
        expect(@default_example.costs).to eq(@default_example.user.rate_at(time, project.id).rate)
      end
    end

    it 'should update cost if a rate is removed' do
      @default_example.spent_on = default_hourly_one.valid_from
      @default_example.hours = 1
      @default_example.save!
      expect(@default_example.costs).to eq(default_hourly_one.rate)
      default_hourly_one.destroy
      @default_example.reload
      expect(@default_example.costs).to eq(default_hourly_three.rate)
      default_hourly_three.destroy
      @default_example.reload
      expect(@default_example.costs).to eq(default_hourly_five.rate)
    end

    it 'shoud be able to switch between default hourly rate and hourly rate' do
      @default_example.user = user2
      @default_example.rate = default_hourly_one
      @default_example.save!
      @default_example.reload
      expect(@default_example.rate).to eq(default_hourly_one)

      (rate = HourlyRate.new.tap do |hr|
        hr.valid_from = 10.days.ago.to_date
        hr.rate       = 1337.0
        hr.user       = @default_example.user
        hr.project    = project
      end).save!

      @default_example.reload
      expect(@default_example.rate).to eq(rate)
      rate.destroy
      @default_example.reload
      expect(@default_example.rate).to eq(default_hourly_one)
    end

    describe '#costs_visible_by?' do
      before do
        project.enabled_module_names = project.enabled_module_names << 'costs_module'
      end

      describe "WHEN the time_entry is assigned to the user
                WHEN the user has the view_own_hourly_rate permission" do
        before do
          is_member(project, user, [:view_own_hourly_rate])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user)).to be_truthy }
      end

      describe "WHEN the time_entry is assigned to the user
                WHEN the user lacks permissions" do
        before do
          is_member(project, user, [])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user)).to be_falsey }
      end

      describe "WHEN the time_entry is assigned to another user
                WHEN the user has the view_hourly_rates permission" do
        before do
          is_member(project, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user2)).to be_truthy }
      end

      describe "WHEN the time_entry is assigned to another user
                WHEN the user has the view_hourly_rates permission in another project" do
        before do
          is_member(project2, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user2)).to be_falsey }
      end
    end
  end

  describe 'visible_by?' do
    context 'when not having the necessary permissions' do
      before do
        is_member(project, user, [])
      end

      it 'is visible' do
        expect(time_entry.visible_by?(user)).to be_falsey
      end
    end

    context 'when having the view_time_entries permission' do
      before do
        is_member(project, user, [:view_time_entries])
      end

      it 'is visible' do
        expect(time_entry.visible_by?(user)).to be_truthy
      end
    end

    context 'when having the view_own_time_entries permission ' +
      'and being the owner of the time entry' do
      before do
        is_member(project, user, [:view_own_time_entries])

        time_entry.user = user
      end

      it 'is visible' do
        expect(time_entry.visible_by?(user)).to be_truthy
      end
    end

    context 'when having the view_own_time_entries permission ' +
      'and not being the owner of the time entry' do
      before do
        is_member(project, user, [:view_own_time_entries])

        time_entry.user = FactoryBot.build :user
      end

      it 'is visible' do
        expect(time_entry.visible_by?(user)).to be_falsey
      end
    end
  end

  describe 'class' do
    describe '#visible' do
      describe "WHEN having the view_time_entries permission
                WHEN querying for a project
                WHEN a time entry from another user is defined" do
        before do
          is_member(project, user2, [:view_time_entries])

          time_entry.save!
        end

        it { expect(TimeEntry.visible(user2, project)).to match_array([time_entry]) }
      end

      describe "WHEN not having the view_time_entries permission
                WHEN querying for a project
                WHEN a time entry from another user is defined" do
        before do
          is_member(project, user2, [])

          time_entry.save!
        end

        it { expect(TimeEntry.visible(user2, project)).to match_array([]) }
      end

      describe "WHEN having the view_own_time_entries permission
                WHEN querying for a project
                WHEN a time entry from another user is defined" do
        before do
          is_member(project, user2, [:view_own_time_entries])
          # don't understand why memberships get loaded on the user
          time_entry2.user.memberships.reload

          time_entry.save!
        end

        it { expect(TimeEntry.visible(user2, project)).to match_array([]) }
      end

      describe "WHEN having the view_own_time_entries permission
                WHEN querying for a project
                WHEN a time entry from the user is defined" do
        before do
          is_member(project, time_entry2.user, [:view_own_time_entries])
          # don't understand why memberships get loaded on the user
          time_entry2.user.memberships.reload

          time_entry2.save!
        end

        it { expect(TimeEntry.visible(time_entry2.user, project)).to match_array([time_entry2]) }
      end
    end

    context 'calculate dates' do
      let(:my_role) { FactoryBot.create(:role, permissions: [:view_own_time_entries]) }
      let(:user3) do
        FactoryBot.create(:user, member_in_project: project, member_through_role: my_role)
      end

      let(:late_time_entry) do
        FactoryBot.create(:time_entry,
                           project: project,
                           work_package: work_package,
                           spent_on: 2.days.ago,
                           hours: hours,
                           user: user3,
                           rate: hourly_one,
                           comments: 'ipsum')
      end
      let(:early_time_entry) do
        FactoryBot.create(:time_entry,
                           project: project,
                           work_package: work_package,
                           spent_on: 4.days.ago,
                           hours: hours,
                           user: user3,
                           rate: hourly_one,
                           comments: 'dolor')
      end
      let(:other_time_entry) do
        FactoryBot.create(:time_entry,
                           project: project,
                           work_package: work_package,
                           spent_on: 6.days.ago,
                           hours: hours,
                           user: user2,
                           rate: hourly_one,
                           comments: 'dolor')
      end
      let(:another_time_entry) do
        FactoryBot.create(:time_entry,
                           project: project,
                           work_package: work_package,
                           spent_on: 1.days.ago,
                           hours: hours,
                           user: user2,
                           rate: hourly_one,
                           comments: 'dolor')
      end

      before do
        early_time_entry.save!
        late_time_entry.save!
        other_time_entry.save!
        another_time_entry.save!

        allow(User).to receive(:current).and_return(user3)
      end
      describe '#earliest_date_for_project' do
        it 'returns the earliest date' do
          expect(TimeEntry.earliest_date_for_project(project)).to eq(early_time_entry.spent_on)
        end
      end

      describe '#latest_date_for_project' do
        it 'returns the latest date' do
          expect(TimeEntry.latest_date_for_project(project)).to eq(late_time_entry.spent_on)
        end
      end
    end
  end
end

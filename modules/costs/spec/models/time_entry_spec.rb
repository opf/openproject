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

RSpec.describe TimeEntry do
  let(:project) { create(:project_with_types, public: false) }
  let(:project2) { create(:project_with_types, public: false) }
  let(:work_package) do
    create(:work_package, project:,
                          type: project.types.first,
                          author: user)
  end
  let(:work_package2) do
    create(:work_package, project: project2,
                          type: project2.types.first,
                          author: user2)
  end
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:date) { Date.today }
  let(:rate) { build(:cost_rate) }
  let!(:hourly_one) { create(:hourly_rate, valid_from: 2.days.ago, project:, user:) }
  let!(:hourly_three) { create(:hourly_rate, valid_from: 4.days.ago, project:, user:) }
  let!(:hourly_five) { create(:hourly_rate, valid_from: 6.days.ago, project:, user:) }
  let!(:default_hourly_one) { create(:default_hourly_rate, valid_from: 2.days.ago, project:, user: user2) }
  let!(:default_hourly_three) { create(:default_hourly_rate, valid_from: 4.days.ago, project:, user: user2) }
  let!(:default_hourly_five) { create(:default_hourly_rate, valid_from: 6.days.ago, project:, user: user2) }
  let(:hours) { 5.0 }
  let(:time_entry) do
    create(:time_entry,
           project:,
           work_package:,
           spent_on: date,
           hours:,
           user:,
           rate: hourly_one,
           comments: "lorem")
  end

  let(:time_entry2) do
    create(:time_entry,
           project:,
           work_package:,
           spent_on: date,
           hours:,
           user:,
           rate: hourly_one,
           comments: "lorem")
  end

  def is_member(project, user, permissions)
    create(:member,
           project:,
           user:,
           roles: [create(:project_role, permissions:)])
  end

  describe "#hours" do
    formats = { "2" => 2.0,
                "21.1" => 21.1,
                "2,1" => 2.1,
                "1,5h" => 1.5,
                "7:12" => 7.2,
                "10h" => 10.0,
                "10 h" => 10.0,
                "45m" => 0.75,
                "45 m" => 0.75,
                "3h15" => 3.25,
                "3h 15" => 3.25,
                "3 h 15" => 3.25,
                "3 h 15m" => 3.25,
                "3 h 15 m" => 3.25,
                "3 hours" => 3.0,
                "12min" => 0.2 }

    formats.each do |from, to|
      it "formats '#{from}'" do
        t = TimeEntry.new(hours: from)
        expect(t.hours)
          .to eql to
      end
    end
  end

  it "always prefers overridden_costs" do
    allow(User).to receive(:current).and_return(user)

    value = rand(500)
    time_entry.overridden_costs = value
    expect(time_entry.overridden_costs).to eq(value)
    expect(time_entry.real_costs).to eq(value)
    time_entry.save!
  end

  describe "given rate" do
    before do
      allow(User).to receive(:current).and_return(user)
      @default_example = time_entry2
    end

    it "returns the current costs depending on the number of hours" do
      101.times do |hours|
        time_entry.hours = hours
        time_entry.save!
        expect(time_entry.costs).to eq(time_entry.rate.rate * hours)
      end
    end

    it "updates cost if a new rate is added at the end" do
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

    it "updates cost if a new rate is added in between" do
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

    it "updates cost if a spent_on changes" do
      time_entry.hours = 1
      (5.days.ago.to_date..Date.today).each do |time|
        time_entry.spent_on = time.to_date
        time_entry.save!
        expect(time_entry.costs).to eq(time_entry.user.rate_at(time, project.id).rate)
      end
    end

    it "updates cost if a rate is removed" do
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

    it "is able to change order of rates (sorted by valid_from)" do
      time_entry.spent_on = hourly_one.valid_from
      time_entry.save!
      expect(time_entry.rate).to eq(hourly_one)
      hourly_one.valid_from = hourly_three.valid_from - 1.day
      hourly_one.save!
      time_entry.reload
      expect(time_entry.rate).to eq(hourly_three)
    end
  end

  describe "default rate" do
    before do
      allow(User).to receive(:current).and_return(user)
      @default_example = time_entry2
    end

    it "returns the current costs depending on the number of hours" do
      101.times do |hours|
        @default_example.hours = hours
        @default_example.save!
        expect(@default_example.costs).to eq(@default_example.rate.rate * hours)
      end
    end

    it "updates cost if a new rate is added at the end" do
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

    it "updates cost if a new rate is added in between" do
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

    it "updates cost if a spent_on changes" do
      @default_example.hours = 1
      (5.days.ago.to_date..Date.today).each do |time|
        @default_example.spent_on = time.to_date
        @default_example.save!
        expect(@default_example.costs).to eq(@default_example.user.rate_at(time, project.id).rate)
      end
    end

    it "updates cost if a rate is removed" do
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

    it "is able to switch between default hourly rate and hourly rate" do
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

    describe "#costs_visible_by?" do
      before do
        project.enabled_module_names = project.enabled_module_names << "costs"
      end

      describe "WHEN the time_entry is assigned to the user " \
               "WHEN the user has the view_own_hourly_rate permission" do
        before do
          is_member(project, user, [:view_own_hourly_rate])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user)).to be_truthy }
      end

      describe "WHEN the time_entry is assigned to the user " \
               "WHEN the user lacks permissions" do
        before do
          is_member(project, user, [])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user)).to be_falsey }
      end

      describe "WHEN the time_entry is assigned to another user " \
               "WHEN the user has the view_hourly_rates permission" do
        before do
          is_member(project, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user2)).to be_truthy }
      end

      describe "WHEN the time_entry is assigned to another user " \
               "WHEN the user has the view_hourly_rates permission in another project" do
        before do
          is_member(project2, user2, [:view_hourly_rates])

          time_entry.user = user
        end

        it { expect(time_entry.costs_visible_by?(user2)).to be_falsey }
      end
    end
  end

  describe "visible_by?" do
    context "when not having the necessary permissions" do
      before do
        is_member(project, user, [])
      end

      it "is visible" do
        expect(time_entry.visible_by?(user)).to be_falsey
      end
    end

    context "when having the view_time_entries permission" do
      before do
        is_member(project, user, [:view_time_entries])
      end

      it "is visible" do
        expect(time_entry.visible_by?(user)).to be_truthy
      end
    end

    context "when having the view_own_time_entries permission " \
            "and being the owner of the time entry" do
      before do
        is_member(project, user, [:view_own_time_entries])

        time_entry.user = user
      end

      it "is visible" do
        expect(time_entry.visible_by?(user)).to be_truthy
      end
    end

    context "when having the view_own_time_entries permission " \
            "and not being the owner of the time entry" do
      before do
        is_member(project, user, [:view_own_time_entries])

        time_entry.user = build :user
      end

      it "is visible" do
        expect(time_entry.visible_by?(user)).to be_falsey
      end
    end
  end
end

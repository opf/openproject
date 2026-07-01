# frozen_string_literal: true

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

RSpec.describe ResourceAllocations::Availability do
  let(:user) { create(:user) }
  let(:monday) { Date.new(2026, 1, 5) }
  let(:tuesday) { Date.new(2026, 1, 6) }
  let(:friday) { Date.new(2026, 1, 9) }

  subject(:availability) { described_class.new(user:) }

  before do
    # Mon-Fri 8h => 2400 minutes of capacity across the work week.
    create(:user_working_hours, user:, valid_from: Date.new(2025, 1, 1))
  end

  def allocate(minutes, start_date: monday, end_date: friday, entity: create(:work_package))
    create(:resource_allocation, principal: user, entity:, allocated_time: minutes, start_date:, end_date:)
  end

  describe "#overbooked? / #overbooked_ranges" do
    it "is overbooked when allocations exceed capacity over a shared window" do
      wp1 = create(:work_package)
      wp2 = create(:work_package)
      allocate(1500, entity: wp1)
      allocate(1500, entity: wp2)

      expect(availability).to be_overbooked
      range = availability.overbooked_ranges.sole
      expect(range).to have_attributes(start_date: monday, end_date: friday, over_by_minutes: 3000 - 2400)
      expect(range.work_package_ids).to contain_exactly(wp1.id, wp2.id)
    end

    it "is not overbooked when the allocations fit" do
      allocate(600)
      allocate(600)

      expect(availability).not_to be_overbooked
      expect(availability.overbooked_ranges).to be_empty
    end

    it "counts allocations across all projects (capacity is user-level)" do
      wp_a = create(:work_package, project: create(:project))
      wp_b = create(:work_package, project: create(:project))
      allocate(1500, entity: wp_a)
      allocate(1500, entity: wp_b)

      expect(availability).to be_overbooked
      expect(availability.overbooked_ranges.sole.work_package_ids).to contain_exactly(wp_a.id, wp_b.id)
    end

    it "ignores filter-based allocations that have no principal" do
      allocate(600)
      create(:resource_allocation, :with_user_filter, start_date: monday, end_date: friday, allocated_time: 5000)

      expect(availability).not_to be_overbooked
    end
  end

  describe "#overbooked_on?" do
    before do
      allocate(1500)
      allocate(1500)
    end

    it "is true for days inside an overbooked range and false outside" do
      expect(availability.overbooked_on?(Date.new(2026, 1, 7))).to be true
      expect(availability.overbooked_on?(Date.new(2026, 1, 12))).to be false
    end
  end

  describe "#optimal_schedule" do
    it "distributes a feasible allocation across the days, summing back to its time" do
      allocate(960, start_date: monday, end_date: tuesday)

      schedule = availability.optimal_schedule
      scheduled_minutes = schedule.by_date.values.flatten.sum(&:minutes)

      expect(scheduled_minutes).to eq(960)
      expect(schedule.capacity_on(monday)).to eq(480)
    end
  end

  describe "#fits?" do
    before { allocate(600) }

    it "is true for a prospective allocation that still fits" do
      expect(availability.fits?(start_date: monday, end_date: friday, minutes: 1000)).to be true
    end

    it "is false for a prospective allocation that would overbook" do
      expect(availability.fits?(start_date: monday, end_date: friday, minutes: 2000)).to be false
    end

    it "can exclude an existing allocation being edited" do
      existing = ResourceAllocation.where(principal: user).sole

      expect(availability.fits?(start_date: monday, end_date: friday, minutes: 2400, exclude_id: existing.id)).to be true
    end
  end

  describe "#overbooking_with" do
    it "is empty when the prospective allocation still fits" do
      allocate(600)

      ranges = availability.overbooking_with(start_date: monday, end_date: friday, minutes: 1000)

      expect(ranges).to be_empty
    end

    it "returns the overbooked range including the candidate, flagged by its id" do
      wp = create(:work_package)
      allocate(1500, entity: wp)
      candidate_wp = create(:work_package)

      range = availability
                .overbooking_with(start_date: monday, end_date: friday, minutes: 1500, work_package_id: candidate_wp.id)
                .sole

      expect(range.work_package_ids).to contain_exactly(wp.id, candidate_wp.id)
      candidate = range.items.find { |item| item.id == described_class::CANDIDATE_ID }
      expect(candidate.work_package_id).to eq(candidate_wp.id)
      expect(candidate.minutes).to eq(1500)
    end

    it "overbooks even without existing allocations when the candidate alone exceeds capacity" do
      # 2400 minutes over Mon-Tue against an 8h/day (960 min) window.
      ranges = availability.overbooking_with(start_date: monday, end_date: tuesday, minutes: 2400)

      expect(ranges).not_to be_empty
    end
  end

  describe "#working_schedules" do
    it "returns the single schedule covering the whole range" do
      expect(availability.working_schedules(monday..friday))
        .to contain_exactly(have_attributes(working_days_summary: "Mon-Fri 8h"))
    end

    it "includes schedules taking effect within the range, in order" do
      switched = create(:user_working_hours, user:, valid_from: tuesday)

      expect(availability.working_schedules(monday..friday).last).to eq(switched)
      expect(availability.working_schedules(monday..friday).size).to eq(2)
    end

    it "drops schedules superseded before the range starts" do
      create(:user_working_hours, user:, valid_from: Date.new(2024, 1, 1))

      expect(availability.working_schedules(monday..friday))
        .to contain_exactly(have_attributes(valid_from: Date.new(2025, 1, 1)))
    end

    it "excludes schedules taking effect after the range ends" do
      create(:user_working_hours, user:, valid_from: Date.new(2027, 1, 1))

      expect(availability.working_schedules(monday..friday))
        .to contain_exactly(have_attributes(valid_from: Date.new(2025, 1, 1)))
    end

    it "starts with a mid-range schedule when none is in effect at the range start" do
      newcomer = create(:user)
      starting = create(:user_working_hours, user: newcomer, valid_from: tuesday)

      expect(described_class.new(user: newcomer).working_schedules(monday..friday)).to eq([starting])
    end

    it "is empty when the user has no working time configured" do
      other = described_class.new(user: create(:user))

      expect(other.working_schedules(monday..friday)).to be_empty
    end
  end

  describe "#utilization_ratio" do
    it "expresses booked time as a percentage of the window's capacity" do
      allocate(1200) # half of the 2400 min Mon-Fri capacity

      expect(availability.utilization_ratio(monday..friday)).to eq(50)
    end

    it "exceeds 100% when the user is overbooked" do
      allocate(3600)

      expect(availability.utilization_ratio(monday..friday)).to eq(150)
    end

    it "rounds to the nearest whole percent" do
      allocate(800) # 800 / 2400 => 33.33%

      expect(availability.utilization_ratio(monday..friday)).to eq(33)
    end

    it "sums every allocation overlapping the window" do
      allocate(600)
      allocate(1200)

      expect(availability.utilization_ratio(monday..friday)).to eq(75)
    end

    it "counts only the portion of an allocation that overlaps the window" do
      # 2000 min booked across Mon-Fri, only 2/5 (800 min) fall in the Mon-Tue window,
      # measured against that window's 960 min capacity
      allocate(2000, start_date: monday, end_date: friday)

      expect(availability.utilization_ratio(monday..tuesday)).to eq(83) # 800 / 960
    end

    it "prorates by working time capacity across user-specific daily hours" do
      part_timer = create(:user)
      create(:user_working_hours, user: part_timer, valid_from: Date.new(2025, 1, 1), monday: 240)
      part_availability = described_class.new(user: part_timer)
      next_monday = Date.new(2026, 1, 12)

      # 720 min booked Fri-Mon is distributed by capacity:
      # 480 to Friday for 8h and 240 to Monday for 4h, filling each day to 100%.
      create(:resource_allocation, principal: part_timer, entity: create(:work_package),
                                   allocated_time: 720, start_date: friday, end_date: next_monday)

      expect(part_availability.utilization_ratio(friday..friday)).to eq(100)            # 480 / 480
      expect(part_availability.utilization_ratio(next_monday..next_monday)).to eq(100)  # 240 / 240
    end

    it "ignores allocations that fall entirely outside the window" do
      allocate(2400, start_date: monday, end_date: tuesday)

      expect(availability.utilization_ratio(friday..friday)).to eq(0)
    end

    it "is nil when the window has no working capacity" do
      weekend = Date.new(2026, 1, 10)..Date.new(2026, 1, 11)

      expect(availability.utilization_ratio(weekend)).to be_nil
    end
  end
end

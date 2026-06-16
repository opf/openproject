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

RSpec.describe ResourceAllocations::WorkingTimeCalendar do
  let(:user) { create(:user) }
  let(:range) { Date.new(2026, 1, 1)..Date.new(2026, 1, 31) }
  let(:monday) { Date.new(2026, 1, 5) }
  let(:saturday) { Date.new(2026, 1, 10) }

  subject(:calendar) { described_class.new(user:, range:) }

  before do
    create(:user_working_hours, user:, valid_from: Date.new(2025, 1, 1)) # Mon-Fri 480, Sat/Sun 0, factor 100
  end

  it "returns the weekday's working minutes" do
    expect(calendar.capacity_on(monday)).to eq(480)
  end

  it "returns zero for a weekday the user does not work" do
    expect(calendar.capacity_on(saturday)).to eq(0)
  end

  context "with an availability factor below 100" do
    before do
      UserWorkingHours.for_user(user).update_all(availability_factor: 50)
    end

    it "scales the capacity" do
      expect(calendar.capacity_on(monday)).to eq(240)
    end
  end

  context "with a newer working hours record mid-range" do
    # The new record takes effect on a Monday so its overridden monday hours are
    # distinguishable from the old record's on the switch boundary.
    let(:switch_day) { Date.new(2026, 1, 19) } # a Monday

    before do
      create(:user_working_hours, user:, valid_from: switch_day, monday: 240)
    end

    it "uses the record valid on each date across the switch" do
      expect(calendar.capacity_on(Date.new(2026, 1, 12))).to eq(480) # Monday before the switch
      expect(calendar.capacity_on(Date.new(2026, 1, 26))).to eq(240) # Monday after the switch
    end

    it "applies the newer record from its valid_from date onwards" do
      expect(calendar.capacity_on(switch_day)).to eq(240) # the switch day itself
    end
  end

  context "when no working hours record is in effect yet" do
    let(:range) { Date.new(2024, 12, 1)..Date.new(2024, 12, 31) }

    it "has zero capacity, even on a weekday the user would otherwise work" do
      # 2024-12-30 is a Monday, but the only record is valid from 2025-01-01.
      expect(calendar.capacity_on(Date.new(2024, 12, 30))).to eq(0)
    end
  end

  context "when the day is inside the user's non-working time" do
    before do
      create(:user_non_working_time, user:, start_date: monday, end_date: monday)
    end

    it "is zero capacity" do
      expect(calendar.capacity_on(monday)).to eq(0)
    end
  end

  context "when the day is a global non-working day" do
    before do
      create(:non_working_day, date: monday)
    end

    it "is zero capacity" do
      expect(calendar.capacity_on(monday)).to eq(0)
    end
  end

  it "ignores the system working_days setting", with_settings: { working_days: [6] } do
    expect(calendar.capacity_on(monday)).to eq(480) # a Monday, despite the setting saying only Saturday
    expect(calendar.capacity_on(saturday)).to eq(0) # the user works zero Saturday minutes
  end

  it "keeps total and prefix_total consistent with the per-day sum" do
    summed = calendar.each_day.sum { |_date, minutes| minutes }
    expect(calendar.total).to eq(summed)
    expect(calendar.prefix_total(range.end)).to eq(summed)
    expect(calendar.prefix_total(range.begin - 1)).to eq(0)
  end
end

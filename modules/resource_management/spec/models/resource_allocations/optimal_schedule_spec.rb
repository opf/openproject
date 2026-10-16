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
require_relative "../../support/resource_allocations/schedule_helpers"

RSpec.describe ResourceAllocations::OptimalSchedule do
  include ResourceAllocations::ScheduleHelpers

  let(:monday) { Date.new(2026, 1, 5) }
  let(:tuesday) { Date.new(2026, 1, 6) }
  let(:wednesday) { Date.new(2026, 1, 7) }
  let(:fitting) { allocation(1, monday, tuesday, 960) }
  let(:exceeding) { allocation(2, monday, monday, 640) }

  subject(:schedule) do
    described_class.new(
      by_date: {
        monday => [scheduled_entry(fitting, monday, 480), scheduled_entry(exceeding, monday, 640, overtime_minutes: 640)],
        tuesday => [scheduled_entry(fitting, tuesday, 480)]
      },
      unplannable: []
    )
  end

  it "defaults to an empty schedule" do
    expect(described_class.new).to have_attributes(by_date: {}, unplannable: [])
  end

  it "returns the entries scheduled on a day, or none" do
    expect(schedule.entries_on(tuesday).map(&:allocation)).to eq([fitting])
    expect(schedule.entries_on(wednesday)).to eq([])
  end

  it "returns the allocations with time on a day" do
    expect(schedule.allocations_on(monday)).to contain_exactly(fitting, exceeding)
    expect(schedule.allocations_on(wednesday)).to eq([])
  end

  it "sums the overtime on a day" do
    expect(schedule.overtime_on(monday)).to eq(640)
    expect(schedule.overtime_on(tuesday)).to eq(0)
    expect(schedule.overtime_on(wednesday)).to eq(0)
  end

  it "lists the days with overtime in order" do
    expect(schedule.overbooked_dates).to eq([monday])
  end
end

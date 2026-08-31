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

RSpec.describe ResourceAllocations::OptimalSchedule do
  let(:monday) { Date.new(2026, 1, 5) }
  let(:tuesday) { Date.new(2026, 1, 6) }

  subject(:schedule) do
    described_class.new(by_date: { monday => %i[entry] }, capacity_by_date: { monday => 480, tuesday => 480 })
  end

  it "defaults to empty collections" do
    expect(described_class.new).to have_attributes(by_date: {}, capacity_by_date: {})
  end

  it "returns the entries scheduled on a day, or none" do
    expect(schedule.entries_on(monday)).to eq(%i[entry])
    expect(schedule.entries_on(tuesday)).to eq([])
  end

  it "returns the capacity on a day, or zero" do
    expect(schedule.capacity_on(monday)).to eq(480)
    expect(schedule.capacity_on(Date.new(2026, 1, 12))).to eq(0)
  end

  it "exposes the dates with capacity" do
    expect(schedule.dates).to contain_exactly(monday, tuesday)
  end
end

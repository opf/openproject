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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ResourceAllocations::ScheduledEntry do
  let(:user) { create(:user) }
  let(:monday) { Date.new(2026, 1, 5) }
  let(:tuesday) { Date.new(2026, 1, 6) }
  let(:wednesday) { Date.new(2026, 1, 7) }
  let!(:started) { create(:resource_allocation, principal: user, allocated_time: 2400) }
  let!(:unscheduled) { create(:resource_allocation, principal: user, allocated_time: 600) }

  before do
    described_class.create!(user:, allocation: started, allocated_on: monday, minutes: 480)
    described_class.create!(user:, allocation: started, allocated_on: tuesday, minutes: 560, overtime_minutes: 80)
    described_class.create!(user:, allocation: started, allocated_on: wednesday, minutes: 480)
  end

  describe ".placed_minutes_by_allocation_id" do
    it "sums the minutes placed before the date, without their overtime" do
      expect(described_class.placed_minutes_by_allocation_id([started, unscheduled], before: wednesday))
        .to eq(started.id => 480 + 480)
    end
  end

  describe ".remaining_minutes_by_allocation" do
    it "subtracts the minutes placed before the date from the allocated time" do
      expect(described_class.remaining_minutes_by_allocation([started, unscheduled], on: wednesday))
        .to eq(started => 2400 - 480 - 480, unscheduled => 600)
    end

    it "is the allocated time without a date" do
      expect(described_class.remaining_minutes_by_allocation([started, unscheduled], on: nil))
        .to eq(started => 2400, unscheduled => 600)
    end
  end
end

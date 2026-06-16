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

RSpec.describe ResourceAllocations::OverbookingAnalysis do
  # Capacity stub: prefix_total is the cumulative capacity up to a date.
  def calendar(capacities)
    Class.new do
      def initialize(capacities) = @capacities = capacities
      def prefix_total(date) = @capacities.select { |day, _| day <= date }.values.sum
    end.new(capacities)
  end

  def item(id, start_date, end_date, minutes)
    ResourceAllocations::WorkItem.new(id:, start_date:, end_date:, minutes:, work_package_id: id)
  end

  let(:mon) { Date.new(2026, 1, 5) }
  let(:tue) { Date.new(2026, 1, 6) }
  let(:wed) { Date.new(2026, 1, 7) }
  let(:thu) { Date.new(2026, 1, 8) }
  let(:fri) { Date.new(2026, 1, 9) }
  let(:week) { { mon => 480, tue => 480, wed => 480, thu => 480, fri => 480 } }

  subject(:ranges) { described_class.new(calendar: calendar(capacities), items:).call }

  context "with a single allocation exceeding its window's capacity" do
    let(:capacities) { { mon => 480, tue => 480 } }
    let(:items) { [item(7, mon, tue, 1200)] }

    it "flags the whole window with the work package and the overflow" do
      expect(ranges.size).to eq(1)
      expect(ranges.first).to have_attributes(
        start_date: mon,
        end_date: tue,
        work_package_ids: [7],
        over_by_minutes: 1200 - 960,
        available_minutes: 960
      )
    end

    it "carries the forced work items so a warning can list them" do
      expect(ranges.first.items.map(&:id)).to eq([7])
      expect(ranges.first.items.map(&:minutes)).to eq([1200])
    end
  end

  context "with two allocations that each fit alone but collide over a shared interval" do
    let(:capacities) { week }
    let(:items) { [item(1, mon, wed, 800), item(2, mon, wed, 800)] }

    it "flags the shared interval naming both work packages" do
      expect(ranges.size).to eq(1)
      expect(ranges.first).to have_attributes(start_date: mon, end_date: wed, over_by_minutes: 1600 - 1440)
      expect(ranges.first.work_package_ids).to contain_exactly(1, 2)
    end
  end

  context "when the allocations fit once shifted within their windows" do
    let(:capacities) { week }
    # The earlier-deadline item is forced into Mon-Tue (960) and fits; together
    # they exactly fill Mon-Wed (1440).
    let(:items) { [item(1, mon, tue, 480), item(2, mon, wed, 960)] }

    it "reports no overbooking" do
      expect(ranges).to be_empty
    end
  end

  context "when the window has no capacity at all (e.g. vacation)" do
    let(:capacities) { { mon => 0, tue => 0 } }
    let(:items) { [item(3, mon, tue, 480)] }

    it "flags the window as fully overbooked" do
      expect(ranges.first).to have_attributes(start_date: mon, end_date: tue, over_by_minutes: 480)
    end
  end

  context "with two separate overbooked days" do
    let(:capacities) { week }
    let(:items) { [item(1, mon, mon, 600), item(2, thu, thu, 600)] }

    it "returns two non-contiguous ranges" do
      expect(ranges.map { |range| [range.start_date, range.end_date] }).to contain_exactly([mon, mon], [thu, thu])
    end
  end
end

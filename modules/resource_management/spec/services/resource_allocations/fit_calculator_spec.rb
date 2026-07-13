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

RSpec.describe ResourceAllocations::FitCalculator do
  # Capacity stub: a plain hash of date => minutes, defaulting to zero.
  def calendar(capacities)
    Class.new do
      def initialize(capacities) = @capacities = capacities
      def capacity_on(date) = @capacities.fetch(date, 0)
    end.new(capacities)
  end

  def item(id, start_date, end_date, minutes)
    ResourceAllocations::WorkItem.new(id:, start_date:, end_date:, minutes:, work_package_id: id)
  end

  let(:mon) { Date.new(2026, 1, 5) }
  let(:tue) { Date.new(2026, 1, 6) }
  let(:wed) { Date.new(2026, 1, 7) }

  subject(:result) { described_class.new(calendar: cal, items:).call }

  context "when the work fits exactly" do
    let(:cal) { calendar(mon => 480, tue => 480) }
    let(:items) { [item(1, mon, tue, 960)] }

    it "fills each day to capacity and is feasible" do
      expect(result).to be_feasible
      expect(result.placements).to eq(1 => { mon => 480, tue => 480 })
      expect(result.daily_load).to eq(mon => 480, tue => 480)
      expect(result.unscheduled).to be_empty
    end
  end

  context "when a day overflows but the window has room" do
    let(:cal) { calendar(mon => 480, tue => 480) }
    let(:items) { [item(1, mon, tue, 600)] }

    it "shifts the overflow onto the next day in the window" do
      expect(result).to be_feasible
      expect(result.placements).to eq(1 => { mon => 480, tue => 120 })
    end
  end

  context "when the work cannot fit even after shifting" do
    let(:cal) { calendar(mon => 480, tue => 0) }
    let(:items) { [item(1, mon, tue, 600)] }

    it "places what it can and reports the remainder as unscheduled" do
      expect(result).not_to be_feasible
      expect(result.placements).to eq(1 => { mon => 480 })
      expect(result.unscheduled).to eq(1 => 120)
    end
  end

  context "with two items competing for a shared day" do
    let(:cal) { calendar(mon => 480, tue => 480) }
    # Item 1 is due Monday; item 2 can slip to Tuesday.
    let(:items) { [item(1, mon, mon, 480), item(2, mon, tue, 480)] }

    it "prioritises the earlier deadline and shifts the other" do
      expect(result).to be_feasible
      expect(result.placements).to eq(
        1 => { mon => 480 },
        2 => { tue => 480 }
      )
    end
  end
end

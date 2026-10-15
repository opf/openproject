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
  let(:thu) { Date.new(2026, 1, 8) }
  let(:fri) { Date.new(2026, 1, 9) }
  let(:next_mon) { Date.new(2026, 1, 12) }

  subject(:result) { described_class.new(calendar: cal, items:).call }

  context "when the work fits exactly" do
    let(:cal) { calendar(mon => 480, tue => 480) }
    let(:items) { [item(1, mon, tue, 960)] }

    it "fills each day to capacity and is feasible" do
      expect(result).to be_feasible
      expect(result.placements).to eq(1 => { mon => 480, tue => 480 })
      expect(result.overtime).to be_empty
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

    it "places what it can and turns the remainder into overtime" do
      expect(result).not_to be_feasible
      expect(result.placements).to eq(1 => { mon => 480 })
      expect(result.overtime).to eq(1 => { mon => 120 })
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

  context "when a later-starting item has the earlier deadline" do
    let(:cal) { calendar(mon => 480, tue => 480, wed => 480, thu => 480, fri => 480) }
    let(:items) { [item(1, mon, fri, 1440), item(2, wed, wed, 480)] }

    it "gives it the day once it starts and resumes the other afterwards" do
      expect(result).to be_feasible
      expect(result.placements).to eq(
        1 => { mon => 480, tue => 480, thu => 480 },
        2 => { wed => 480 }
      )
    end
  end

  context "with equal deadlines" do
    let(:cal) { calendar(wed => 480) }
    let(:items) { [item(1, tue, wed, 480), item(2, mon, wed, 480)] }

    it "prioritises the earlier start" do
      expect(result.placements).to eq(2 => { wed => 480 })
      expect(result.overtime).to eq(1 => { wed => 480 })
    end
  end

  context "with equal deadlines and starts" do
    let(:cal) { calendar(mon => 480) }
    let(:items) { [item(2, mon, mon, 480), item(1, mon, mon, 480)] }

    it "prioritises the lower id regardless of the given order" do
      expect(result.placements).to eq(1 => { mon => 480 })
      expect(result.overtime).to eq(2 => { mon => 480 })
    end
  end

  context "when an item's window ends with work left" do
    let(:cal) { calendar(mon => 480, tue => 480) }
    let(:items) { [item(1, mon, mon, 600), item(2, mon, tue, 480)] }

    it "turns the remainder into overtime within the window instead of placing it after" do
      expect(result.placements).to eq(
        1 => { mon => 480 },
        2 => { tue => 480 }
      )
      expect(result.overtime).to eq(1 => { mon => 120 })
    end
  end

  context "with a non-working day inside the window" do
    let(:cal) { calendar(mon => 480, tue => 0, wed => 480) }
    let(:items) { [item(1, mon, wed, 960)] }

    it "skips the day without capacity" do
      expect(result).to be_feasible
      expect(result.placements).to eq(1 => { mon => 480, wed => 480 })
    end
  end

  context "with a gap between items" do
    let(:cal) { calendar(mon => 480, next_mon => 480) }
    let(:items) { [item(1, mon, mon, 240), item(2, next_mon, next_mon, 240)] }

    it "places the items on both sides of the gap" do
      expect(result.placements).to eq(
        1 => { mon => 240 },
        2 => { next_mon => 240 }
      )
    end
  end

  context "with an item without minutes" do
    let(:cal) { calendar(mon => 480, tue => 480) }
    let(:items) { [item(1, mon, tue, 0), item(2, mon, tue, 480)] }

    it "neither places it nor gives it overtime" do
      expect(result).to be_feasible
      expect(result.placements).to eq(2 => { mon => 480 })
    end
  end

  context "without items" do
    let(:cal) { calendar({}) }
    let(:items) { [] }

    it "returns an empty, feasible result" do
      expect(result).to be_feasible
      expect(result.placements).to be_empty
      expect(result.overtime).to be_empty
    end
  end

  describe "overtime" do
    let(:sat) { Date.new(2026, 1, 10) }
    let(:sun) { Date.new(2026, 1, 11) }
    let(:week) { { mon => 480, tue => 480, wed => 480, thu => 480, fri => 480 } }

    context "when the work fits" do
      let(:cal) { calendar(week) }
      let(:items) { [item(1, mon, fri, 2400)] }

      it "has no overtime" do
        expect(result.overtime).to be_empty
      end
    end

    context "when an item exceeds its window's capacity" do
      let(:cal) { calendar(week) }
      let(:items) { [item(1, mon, fri, 2400 + 240)] }

      it "spreads the excess evenly over the working days instead of piling it onto one" do
        expect(result).not_to be_feasible
        expect(result.placements).to eq(1 => week)
        expect(result.overtime).to eq(1 => { mon => 48, tue => 48, wed => 48, thu => 48, fri => 48 })
      end
    end

    context "with days of different capacity" do
      let(:cal) { calendar(mon => 480, tue => 240) }
      let(:items) { [item(1, mon, tue, 720 + 90)] }

      it "distributes the excess in proportion to each day's capacity" do
        expect(result.overtime).to eq(1 => { mon => 60, tue => 30 })
      end
    end

    context "with days without capacity in the window" do
      let(:cal) { calendar(fri => 480, next_mon => 480) }
      let(:items) { [item(1, fri, next_mon, 960 + 120)] }

      it "puts no overtime on them" do
        expect(result.overtime).to eq(1 => { fri => 60, next_mon => 60 })
      end
    end

    context "when the excess does not divide evenly" do
      let(:cal) { calendar(mon => 480, tue => 480, wed => 480) }
      let(:items) { [item(1, mon, wed, 1440 + 100)] }

      it "keeps the total exact, handing the remainder to the earlier day" do
        expect(result.overtime).to eq(1 => { mon => 34, tue => 33, wed => 33 })
      end
    end

    context "when the shares have different fractional parts" do
      let(:cal) { calendar(mon => 480, tue => 240, wed => 240) }
      # Exact shares are 5, 2.5 and 2.5.
      let(:items) { [item(1, mon, wed, 960 + 10)] }

      it "hands the remainder out by largest fractional part" do
        expect(result.overtime).to eq(1 => { mon => 5, tue => 3, wed => 2 })
      end
    end

    context "when the window contains no working day" do
      let(:cal) { calendar({}) }
      let(:items) { [item(1, sat, sun, 240)] }

      it "places no overtime and reports the time as unplannable" do
        expect(result).not_to be_feasible
        expect(result.overtime).to be_empty
        expect(result.unplannable).to eq(1 => 240)
      end
    end

    context "with items competing for the same days" do
      let(:cal) { calendar(mon => 480, tue => 480, wed => 480) }
      let(:items) { [item(1, mon, tue, 960), item(2, mon, wed, 960)] }

      it "gives the overtime to the item that could not be placed, over its own window" do
        expect(result.placements).to eq(
          1 => { mon => 480, tue => 480 },
          2 => { wed => 480 }
        )
        expect(result.overtime).to eq(2 => { mon => 160, tue => 160, wed => 160 })
      end
    end
  end
end

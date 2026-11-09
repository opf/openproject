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
require_relative "../../support/resource_allocations/schedule_helpers"

RSpec.describe ResourceAllocations::FitCalculator do
  include ResourceAllocations::ScheduleHelpers

  let(:mon) { Date.new(2026, 1, 5) }
  let(:tue) { Date.new(2026, 1, 6) }
  let(:wed) { Date.new(2026, 1, 7) }
  let(:thu) { Date.new(2026, 1, 8) }
  let(:fri) { Date.new(2026, 1, 9) }
  let(:next_mon) { Date.new(2026, 1, 12) }

  subject(:result) { described_class.new(calendar: cal, allocations:).call }

  context "when the work fits exactly" do
    let(:cal) { static_calendar(mon => 480, tue => 480) }
    let(:first) { allocation(1, mon, tue, 960) }
    let(:allocations) { [first] }

    it "fills each day to capacity and is feasible" do
      expect(result).to be_feasible
      expect(result.placements).to eq(first => { mon => 480, tue => 480 })
      expect(result.overtime).to be_empty
    end
  end

  context "when a day overflows but the window has room" do
    let(:cal) { static_calendar(mon => 480, tue => 480) }
    let(:first) { allocation(1, mon, tue, 600) }
    let(:allocations) { [first] }

    it "shifts the overflow onto the next day in the window" do
      expect(result).to be_feasible
      expect(result.placements).to eq(first => { mon => 480, tue => 120 })
    end
  end

  context "when the work cannot fit even after shifting" do
    let(:cal) { static_calendar(mon => 480, tue => 0) }
    let(:first) { allocation(1, mon, tue, 600) }
    let(:allocations) { [first] }

    it "places what it can and turns the remainder into overtime" do
      expect(result).not_to be_feasible
      expect(result.placements).to eq(first => { mon => 480 })
      expect(result.overtime).to eq(first => { mon => 120 })
    end
  end

  context "with two allocations competing for a shared day" do
    let(:cal) { static_calendar(mon => 480, tue => 480) }
    let(:due_monday) { allocation(1, mon, mon, 480) }
    let(:due_tuesday) { allocation(2, mon, tue, 480) }
    let(:allocations) { [due_monday, due_tuesday] }

    it "prioritizes the earlier deadline and shifts the other" do
      expect(result).to be_feasible
      expect(result.placements).to eq(
        due_monday => { mon => 480 },
        due_tuesday => { tue => 480 }
      )
    end
  end

  context "when a later-starting allocation has the earlier deadline" do
    let(:cal) { static_calendar(mon => 480, tue => 480, wed => 480, thu => 480, fri => 480) }
    let(:whole_week) { allocation(1, mon, fri, 1440) }
    let(:wednesday_only) { allocation(2, wed, wed, 480) }
    let(:allocations) { [whole_week, wednesday_only] }

    it "gives it the day once it starts and resumes the other afterwards" do
      expect(result).to be_feasible
      expect(result.placements).to eq(
        whole_week => { mon => 480, tue => 480, thu => 480 },
        wednesday_only => { wed => 480 }
      )
    end
  end

  context "with equal deadlines" do
    let(:cal) { static_calendar(wed => 480) }
    let(:later_start) { allocation(1, tue, wed, 480) }
    let(:earlier_start) { allocation(2, mon, wed, 480) }
    let(:allocations) { [later_start, earlier_start] }

    it "prioritizes the earlier start" do
      expect(result.placements).to eq(earlier_start => { wed => 480 })
      expect(result.overtime).to eq(later_start => { wed => 480 })
    end
  end

  context "with equal deadlines and starts" do
    let(:cal) { static_calendar(mon => 480) }
    let(:higher_id) { allocation(2, mon, mon, 480) }
    let(:lower_id) { allocation(1, mon, mon, 480) }
    let(:allocations) { [higher_id, lower_id] }

    it "prioritizes the lower id regardless of the given order" do
      expect(result.placements).to eq(lower_id => { mon => 480 })
      expect(result.overtime).to eq(higher_id => { mon => 480 })
    end
  end

  context "with equal deadlines and starts and an allocation that is not persisted yet" do
    let(:cal) { static_calendar(mon => 480) }
    let(:unsaved) { allocation(nil, mon, mon, 480) }
    let(:persisted) { allocation(1, mon, mon, 480) }
    let(:allocations) { [unsaved, persisted] }

    it "prioritizes the persisted one" do
      expect(result.placements).to eq(persisted => { mon => 480 })
      expect(result.overtime).to eq(unsaved => { mon => 480 })
    end
  end

  context "when an allocation's window ends with work left" do
    let(:cal) { static_calendar(mon => 480, tue => 480) }
    let(:first) { allocation(1, mon, mon, 600) }
    let(:second) { allocation(2, mon, tue, 480) }
    let(:allocations) { [first, second] }

    it "turns the remainder into overtime within the window instead of placing it after" do
      expect(result.placements).to eq(
        first => { mon => 480 },
        second => { tue => 480 }
      )
      expect(result.overtime).to eq(first => { mon => 120 })
    end
  end

  context "with a non-working day inside the window" do
    let(:cal) { static_calendar(mon => 480, tue => 0, wed => 480) }
    let(:first) { allocation(1, mon, wed, 960) }
    let(:allocations) { [first] }

    it "skips the day without capacity" do
      expect(result).to be_feasible
      expect(result.placements).to eq(first => { mon => 480, wed => 480 })
    end
  end

  context "with a gap between allocations" do
    let(:cal) { static_calendar(mon => 480, next_mon => 480) }
    let(:first) { allocation(1, mon, mon, 240) }
    let(:second) { allocation(2, next_mon, next_mon, 240) }
    let(:allocations) { [first, second] }

    it "places the allocations on both sides of the gap" do
      expect(result.placements).to eq(
        first => { mon => 240 },
        second => { next_mon => 240 }
      )
    end
  end

  context "with an allocation without minutes" do
    let(:cal) { static_calendar(mon => 480, tue => 480) }
    let(:empty) { allocation(1, mon, tue, 0) }
    let(:second) { allocation(2, mon, tue, 480) }
    let(:allocations) { [empty, second] }

    it "neither places it nor gives it overtime" do
      expect(result).to be_feasible
      expect(result.placements).to eq(second => { mon => 480 })
    end
  end

  context "without allocations" do
    let(:cal) { static_calendar({}) }
    let(:allocations) { [] }

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
      let(:cal) { static_calendar(week) }
      let(:allocations) { [allocation(1, mon, fri, 2400)] }

      it "has no overtime" do
        expect(result.overtime).to be_empty
      end
    end

    context "when an allocation exceeds its window's capacity" do
      let(:cal) { static_calendar(week) }
      let(:first) { allocation(1, mon, fri, 2400 + 240) }
      let(:allocations) { [first] }

      it "spreads the excess evenly over the working days instead of piling it onto one" do
        expect(result).not_to be_feasible
        expect(result.placements).to eq(first => week)
        expect(result.overtime).to eq(first => { mon => 48, tue => 48, wed => 48, thu => 48, fri => 48 })
      end
    end

    context "with days of different capacity" do
      let(:cal) { static_calendar(mon => 480, tue => 240) }
      let(:first) { allocation(1, mon, tue, 720 + 90) }
      let(:allocations) { [first] }

      it "distributes the excess in proportion to each day's capacity" do
        expect(result.overtime).to eq(first => { mon => 60, tue => 30 })
      end
    end

    context "with days without capacity in the window" do
      let(:cal) { static_calendar(fri => 480, next_mon => 480) }
      let(:first) { allocation(1, fri, next_mon, 960 + 120) }
      let(:allocations) { [first] }

      it "puts no overtime on them" do
        expect(result.overtime).to eq(first => { fri => 60, next_mon => 60 })
      end
    end

    context "when the excess does not divide evenly" do
      let(:cal) { static_calendar(mon => 480, tue => 480, wed => 480) }
      let(:first) { allocation(1, mon, wed, 1440 + 100) }
      let(:allocations) { [first] }

      it "keeps the total exact, handing the remainder to the earlier day" do
        expect(result.overtime).to eq(first => { mon => 34, tue => 33, wed => 33 })
      end
    end

    context "when the shares have different fractional parts" do
      let(:cal) { static_calendar(mon => 480, tue => 240, wed => 240) }
      let(:first) { allocation(1, mon, wed, 960 + 10) }
      let(:allocations) { [first] }

      it "hands the remainder out by largest fractional part" do
        expect(result.overtime).to eq(first => { mon => 5, tue => 3, wed => 2 })
      end
    end

    context "when the window contains no working day" do
      let(:cal) { static_calendar({}) }
      let(:first) { allocation(1, sat, sun, 240) }
      let(:allocations) { [first] }

      it "places no overtime and reports the time as unplannable" do
        expect(result).not_to be_feasible
        expect(result.overtime).to be_empty
        expect(result.unplannable).to eq(first => 240)
      end
    end

    context "with allocations competing for the same days" do
      let(:cal) { static_calendar(mon => 480, tue => 480, wed => 480) }
      let(:fitting) { allocation(1, mon, tue, 960) }
      let(:exceeding) { allocation(2, mon, wed, 960) }
      let(:allocations) { [fitting, exceeding] }

      it "gives the overtime to the allocation that could not be placed, over its own window" do
        expect(result.placements).to eq(
          fitting => { mon => 480, tue => 480 },
          exceeding => { wed => 480 }
        )
        expect(result.overtime).to eq(exceeding => { mon => 160, tue => 160, wed => 160 })
      end
    end
  end

  describe "resuming from a date" do
    let(:cal) { static_calendar(mon => 480, tue => 480, wed => 480, thu => 480, fri => 240) }
    let(:whole_week) { allocation(1, mon, fri, 1440) }
    let(:wednesday_only) { allocation(2, wed, wed, 480) }
    let(:exceeding) { allocation(3, tue, thu, 960) }
    let(:allocations) { [whole_week, wednesday_only, exceeding] }

    (Date.new(2026, 1, 5)..Date.new(2026, 1, 9)).each do |from|
      context "when resumed on #{from} with the work remaining at its start" do
        let(:remaining) do
          allocations.index_with do |allocation|
            placed_before = result.placements.fetch(allocation, {}).sum { |day, minutes| day < from ? minutes : 0 }
            allocation.allocated_time - placed_before
          end
        end
        let(:placements_from) do
          result.placements
            .transform_values { |by_date| by_date.select { |day, _| day >= from } }
            .reject { |_, by_date| by_date.empty? }
        end

        subject(:resumed) { described_class.new(calendar: cal, allocations:, from:, remaining:).call }

        it "places what the full run places from that day on" do
          expect(resumed.placements).to eq(placements_from)
        end

        it "spreads the same overtime as the full run" do
          expect(resumed.overtime).to eq(result.overtime)
        end
      end
    end

    it "spreads overtime over the whole window of an allocation that started before the date" do
      resumed = described_class.new(calendar: cal, allocations: [exceeding], from: wed,
                                    remaining: { exceeding => 960 }).call

      expect(resumed.placements).to eq(exceeding => { wed => 480, thu => 480 })
      expect(resumed.overtime).to be_empty

      resumed = described_class.new(calendar: cal, allocations: [exceeding], from: thu,
                                    remaining: { exceeding => 960 }).call

      expect(resumed.placements).to eq(exceeding => { thu => 480 })
      expect(resumed.overtime).to eq(exceeding => { tue => 160, wed => 160, thu => 160 })
    end

    it "does not place an allocation without work remaining" do
      resumed = described_class.new(calendar: cal, allocations: [whole_week], from: wed,
                                    remaining: { whole_week => 0 }).call

      expect(resumed).to be_feasible
      expect(resumed.placements).to be_empty
    end
  end
end

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

require "rails_helper"
require_relative "shared_examples_days"

RSpec.describe WorkPackages::Shared::WorkingDays do
  subject { described_class.new }

  friday_2022_07_29 = Date.new(2022, 7, 29)
  saturday_2022_07_30 = Date.new(2022, 7, 30)
  sunday_2022_07_31 = Date.new(2022, 7, 31)
  monday_2022_08_01 = Date.new(2022, 8, 1)
  wednesday_2022_08_03 = Date.new(2022, 8, 3)

  describe "#duration" do
    it "returns the duration for a given start date and due date" do
      expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
    end

    context "without any week days created" do
      it "considers all days as working days and returns the number of days between two dates, inclusive" do
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(51)
      end
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      include_examples "it returns duration", 0, sunday_2022_07_31, sunday_2022_07_31
      include_examples "it returns duration", 5, sunday_2022_07_31, Date.new(2022, 8, 5)
      include_examples "it returns duration", 5, sunday_2022_07_31, Date.new(2022, 8, 6)
      include_examples "it returns duration", 5, sunday_2022_07_31, Date.new(2022, 8, 7)
      include_examples "it returns duration", 6, sunday_2022_07_31, Date.new(2022, 8, 8)
      include_examples "it returns duration", 7, sunday_2022_07_31, Date.new(2022, 8, 9)

      include_examples "it returns duration", 1, monday_2022_08_01, monday_2022_08_01
      include_examples "it returns duration", 5, monday_2022_08_01, Date.new(2022, 8, 5)
      include_examples "it returns duration", 5, monday_2022_08_01, Date.new(2022, 8, 6)
      include_examples "it returns duration", 5, monday_2022_08_01, Date.new(2022, 8, 7)
      include_examples "it returns duration", 6, monday_2022_08_01, Date.new(2022, 8, 8)
      include_examples "it returns duration", 7, monday_2022_08_01, Date.new(2022, 8, 9)

      include_examples "it returns duration", 3, wednesday_2022_08_03, Date.new(2022, 8, 5)
      include_examples "it returns duration", 3, wednesday_2022_08_03, Date.new(2022, 8, 6)
      include_examples "it returns duration", 3, wednesday_2022_08_03, Date.new(2022, 8, 7)
      include_examples "it returns duration", 4, wednesday_2022_08_03, Date.new(2022, 8, 8)
      include_examples "it returns duration", 5, wednesday_2022_08_03, Date.new(2022, 8, 9)
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "it returns duration", 0, Date.new(2022, 12, 25), Date.new(2022, 12, 25)
      include_examples "it returns duration", 1, Date.new(2022, 12, 24), Date.new(2022, 12, 25)
      include_examples "it returns duration", 8, Date.new(2022, 12, 24), Date.new(2023, 1, 2)
    end

    context "without start date" do
      it "returns nil" do
        expect(subject.duration(nil, sunday_2022_07_31)).to be_nil
      end
    end

    context "without due date" do
      it "returns nil" do
        expect(subject.duration(sunday_2022_07_31, nil)).to be_nil
      end
    end
  end

  describe "#start_date" do
    it "returns the start date for a due date and a duration" do
      expect(subject.start_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
    end

    it "raises an error if duration is 0 or negative" do
      expect { subject.start_date(monday_2022_08_01, 0) }
        .to raise_error ArgumentError, "duration must be strictly positive"
      expect { subject.start_date(monday_2022_08_01, -10) }
        .to raise_error ArgumentError, "duration must be strictly positive"
    end

    it "returns nil if due_date is nil" do
      expect(subject.start_date(nil, 1)).to be_nil
    end

    it "returns nil if duration is nil" do
      expect(subject.start_date(monday_2022_08_01, nil)).to be_nil
    end

    context "without any week days created" do
      it "returns the due date considering all days as working days" do
        expect(subject.start_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
        expect(subject.start_date(monday_2022_08_01, 7)).to eq(monday_2022_08_01 - 6) # Tuesday of previous week
      end
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      include_examples "start_date", due_date: monday_2022_08_01, duration: 1, expected: monday_2022_08_01
      include_examples "start_date", due_date: monday_2022_08_01, duration: 5, expected: monday_2022_08_01 - 6.days
      include_examples "start_date", due_date: wednesday_2022_08_03, duration: 10, expected: wednesday_2022_08_03 - 13.days

      # contrived one... But can happen when date is coming from an external entity, like soonest start.
      include_examples "start_date", due_date: saturday_2022_07_30, duration: 1, expected: friday_2022_07_29
      include_examples "start_date", due_date: saturday_2022_07_30, duration: 2, expected: friday_2022_07_29 - 1.day
      include_examples "start_date", due_date: saturday_2022_07_30, duration: 6, expected: friday_2022_07_29 - 7.days
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "start_date", due_date: Date.new(2022, 12, 26), duration: 2, expected: Date.new(2022, 12, 24)
      include_examples "start_date", due_date: Date.new(2023, 1, 2), duration: 8, expected: Date.new(2022, 12, 24)
    end
  end

  describe "#due_date" do
    it "returns the due date for a start date and a duration" do
      expect(subject.due_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
    end

    it "raises an error if duration is 0 or negative" do
      expect { subject.due_date(monday_2022_08_01, 0) }
        .to raise_error ArgumentError, "duration must be strictly positive"
      expect { subject.due_date(monday_2022_08_01, -10) }
        .to raise_error ArgumentError, "duration must be strictly positive"
    end

    it "returns nil if start_date is nil" do
      expect(subject.due_date(nil, 1)).to be_nil
    end

    it "returns nil if duration is nil" do
      expect(subject.due_date(monday_2022_08_01, nil)).to be_nil
    end

    context "without any week days created" do
      it "returns the due date considering all days as working days" do
        expect(subject.due_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
        expect(subject.due_date(monday_2022_08_01, 7)).to eq(monday_2022_08_01 + 6) # Sunday of same week
      end
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      include_examples "due_date", start_date: monday_2022_08_01, duration: 1, expected: monday_2022_08_01
      include_examples "due_date", start_date: monday_2022_08_01, duration: 5, expected: monday_2022_08_01 + 4.days
      include_examples "due_date", start_date: wednesday_2022_08_03, duration: 10, expected: wednesday_2022_08_03 + 13.days

      # contrived one... But can happen when date is coming from an external entity, like soonest start.
      include_examples "due_date", start_date: saturday_2022_07_30, duration: 1, expected: monday_2022_08_01
      include_examples "due_date", start_date: saturday_2022_07_30, duration: 2, expected: monday_2022_08_01 + 1.day
      include_examples "due_date", start_date: saturday_2022_07_30, duration: 6, expected: monday_2022_08_01 + 7.days
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "due_date", start_date: Date.new(2022, 12, 24), duration: 2, expected: Date.new(2022, 12, 26)
      include_examples "due_date", start_date: Date.new(2022, 12, 24), duration: 8, expected: Date.new(2023, 1, 2)
    end
  end

  describe "#soonest_working_day" do
    it "returns the soonest working day from the given day" do
      expect(subject.soonest_working_day(sunday_2022_07_31)).to eq(sunday_2022_07_31)
    end

    it "returns nil if given date is nil" do
      expect(subject.soonest_working_day(nil)).to be_nil
    end

    context "with lag" do
      it "returns the soonest working day from the given day, after a configurable lag of working days" do
        expect(subject.soonest_working_day(sunday_2022_07_31, lag: nil)).to eq(sunday_2022_07_31)
        expect(subject.soonest_working_day(sunday_2022_07_31, lag: 0)).to eq(sunday_2022_07_31)
        expect(subject.soonest_working_day(sunday_2022_07_31, lag: 1)).to eq(monday_2022_08_01)
      end

      it "works with big lag value like 100_000" do
        # First implementation was recursive and failed with SystemStackError: stack level too deep
        expect { subject.soonest_working_day(sunday_2022_07_31, lag: 100_000) }
          .not_to raise_error
      end
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      include_examples "soonest working day", date: friday_2022_07_29, expected: friday_2022_07_29
      include_examples "soonest working day", date: saturday_2022_07_30, expected: monday_2022_08_01
      include_examples "soonest working day", date: sunday_2022_07_31, expected: monday_2022_08_01
      include_examples "soonest working day", date: monday_2022_08_01, expected: monday_2022_08_01

      context "with lag" do
        include_examples "soonest working day with lag", date: friday_2022_07_29, lag: 0, expected: friday_2022_07_29
        include_examples "soonest working day with lag", date: saturday_2022_07_30, lag: 0, expected: monday_2022_08_01
        include_examples "soonest working day with lag", date: sunday_2022_07_31, lag: 0, expected: monday_2022_08_01
        include_examples "soonest working day with lag", date: monday_2022_08_01, lag: 0, expected: monday_2022_08_01

        include_examples "soonest working day with lag", date: friday_2022_07_29, lag: 1, expected: monday_2022_08_01
        include_examples "soonest working day with lag", date: saturday_2022_07_30, lag: 1, expected: Date.new(2022, 8, 2)
        include_examples "soonest working day with lag", date: sunday_2022_07_31, lag: 1, expected: Date.new(2022, 8, 2)
        include_examples "soonest working day with lag", date: monday_2022_08_01, lag: 1, expected: Date.new(2022, 8, 2)

        include_examples "soonest working day with lag", date: friday_2022_07_29, lag: 8, expected: Date.new(2022, 8, 10)
      end
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "soonest working day", date: Date.new(2022, 12, 25), expected: Date.new(2022, 12, 26)
      include_examples "soonest working day", date: Date.new(2022, 12, 31), expected: Date.new(2022, 12, 31)
      include_examples "soonest working day", date: Date.new(2023, 1, 1), expected: Date.new(2023, 1, 2)

      context "with lag" do
        include_examples "soonest working day with lag", date: Date.new(2022, 12, 24), lag: 7, expected: Date.new(2023, 1, 2)
      end
    end

    context "with no working days", :no_working_days do
      it "prevents looping infinitely by raising a runtime error" do
        expect { subject.soonest_working_day(sunday_2022_07_31) }
          .to raise_error(RuntimeError, "cannot have all week days as non-working days")
      end
    end
  end
end

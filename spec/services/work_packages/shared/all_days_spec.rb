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

RSpec.describe WorkPackages::Shared::AllDays do
  subject { described_class.new }

  sunday_2022_07_31 = Date.new(2022, 7, 31)

  describe "#duration" do
    context "without any week days created" do
      it "considers all days as working days and returns the number of days between two dates, inclusive" do
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(51)
      end
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      it "considers all days as working days and returns the number of days between two dates, inclusive" do
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(51)
      end
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "it returns duration", 365, Date.new(2022, 1, 1), Date.new(2022, 12, 31)
      include_examples "it returns duration", 365 * 2, Date.new(2022, 1, 1), Date.new(2023, 12, 31)
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
      expect(subject.start_date(sunday_2022_07_31, 1)).to eq(sunday_2022_07_31)
      expect(subject.start_date(sunday_2022_07_31 + 9.days, 10)).to eq(sunday_2022_07_31)
    end

    it "raises an error if duration is 0 or negative" do
      expect { subject.start_date(sunday_2022_07_31, 0) }
        .to raise_error ArgumentError, "duration must be strictly positive"
      expect { subject.start_date(sunday_2022_07_31, -10) }
        .to raise_error ArgumentError, "duration must be strictly positive"
    end

    it "returns nil if due_date is nil" do
      expect(subject.start_date(nil, 1)).to be_nil
    end

    it "returns nil if duration is nil" do
      expect(subject.start_date(sunday_2022_07_31, nil)).to be_nil
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      include_examples "start_date", due_date: sunday_2022_07_31, duration: 1, expected: sunday_2022_07_31
      include_examples "start_date", due_date: sunday_2022_07_31, duration: 5, expected: sunday_2022_07_31 - 4.days
      include_examples "start_date", due_date: sunday_2022_07_31, duration: 10, expected: sunday_2022_07_31 - 9.days
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "start_date", due_date: Date.new(2022, 12, 31), duration: 365, expected: Date.new(2022, 1, 1)
      include_examples "start_date", due_date: Date.new(2023, 12, 31), duration: 365 * 2, expected: Date.new(2022, 1, 1)
    end
  end

  describe "#due_date" do
    it "returns the due date for a start date and a duration" do
      expect(subject.due_date(sunday_2022_07_31, 1)).to eq(sunday_2022_07_31)
      expect(subject.due_date(sunday_2022_07_31, 10)).to eq(sunday_2022_07_31 + 9.days)
    end

    it "raises an error if duration is 0 or negative" do
      expect { subject.due_date(sunday_2022_07_31, 0) }
        .to raise_error ArgumentError, "duration must be strictly positive"
      expect { subject.due_date(sunday_2022_07_31, -10) }
        .to raise_error ArgumentError, "duration must be strictly positive"
    end

    it "returns nil if start_date is nil" do
      expect(subject.due_date(nil, 1)).to be_nil
    end

    it "returns nil if duration is nil" do
      expect(subject.due_date(sunday_2022_07_31, nil)).to be_nil
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      include_examples "due_date", start_date: sunday_2022_07_31, duration: 1, expected: sunday_2022_07_31
      include_examples "due_date", start_date: sunday_2022_07_31, duration: 5, expected: sunday_2022_07_31 + 4.days
      include_examples "due_date", start_date: sunday_2022_07_31, duration: 10, expected: sunday_2022_07_31 + 9.days
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "due_date", start_date: Date.new(2022, 1, 1), duration: 365, expected: Date.new(2022, 12, 31)
      include_examples "due_date", start_date: Date.new(2022, 1, 1), duration: 365 * 2, expected: Date.new(2023, 12, 31)
    end
  end

  describe "#soonest_working_day" do
    it "returns the given day" do
      expect(subject.soonest_working_day(sunday_2022_07_31)).to eq(sunday_2022_07_31)
    end

    it "returns nil if given date is nil" do
      expect(subject.soonest_working_day(nil)).to be_nil
    end

    context "with lag" do
      it "returns the soonest working day from the given day, after a configurable lag of working days" do
        expect(subject.soonest_working_day(sunday_2022_07_31, lag: nil)).to eq(sunday_2022_07_31)
        expect(subject.soonest_working_day(sunday_2022_07_31, lag: 0)).to eq(sunday_2022_07_31)
        expect(subject.soonest_working_day(sunday_2022_07_31, lag: 1)).to eq(Date.new(2022, 8, 1))
      end
    end

    context "with weekend days (Saturday and Sunday)", :weekend_saturday_sunday do
      it "returns the given day" do
        expect(subject.soonest_working_day(sunday_2022_07_31)).to eq(sunday_2022_07_31)
      end

      context "with lag" do
        include_examples "soonest working day with lag", date: Date.new(2022, 1, 1), lag: 30, expected: Date.new(2022, 1, 31)
      end
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      it "returns the given day" do
        expect(subject.soonest_working_day(Date.new(2022, 12, 25))).to eq(Date.new(2022, 12, 25))
      end

      context "with lag" do
        include_examples "soonest working day with lag", date: Date.new(2022, 12, 24),
                                                         lag: 7,
                                                         expected: Date.new(2022, 12, 31)
      end
    end
  end
end

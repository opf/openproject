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

Date::DATE_FORMATS[:wday_date] = "%a %-d %b %Y" # Fri 5 Aug 2022

RSpec.shared_context "with weekend days Saturday and Sunday" do
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
end

RSpec.shared_context "with non working days from this and next year" do
  shared_let(:first_of_may) { create(:non_working_day, date: Date.new(Date.current.year, 5, 1)) }
  shared_let(:christmas) { create(:non_working_day, date: Date.new(Date.current.year, 12, 25)) }
  shared_let(:new_year_day) { create(:non_working_day, date: Date.new(Date.current.year + 1, 1, 1)) }
end

RSpec.shared_context "with non working days Christmas 2022 and new year 2023" do
  shared_let(:christmas) { create(:non_working_day, date: Date.new(2022, 12, 25)) }
  shared_let(:new_year_day) { create(:non_working_day, date: Date.new(2023, 1, 1)) }
end

RSpec.shared_context "with no working days" do
  include_context "with weekend days Saturday and Sunday"

  before do
    week_with_no_working_days
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with weekend days Saturday and Sunday", :weekend_saturday_sunday
  rspec.include_context "with non working days Christmas 2022 and new year 2023", :christmas_2022_new_year_2023
  rspec.include_context "with non working days from this and next year", :non_working_days_from_this_and_next_year
  rspec.include_context "with no working days", :no_working_days
end

RSpec.shared_examples "it returns duration" do |expected_duration, start_date, due_date|
  from_date_format = "%a %-d"
  from_date_format += " %b" if [start_date.month, start_date.year] != [due_date.month, due_date.year]
  from_date_format += " %Y" if start_date.year != due_date.year

  it "from #{start_date.strftime(from_date_format)} " \
     "to #{due_date.to_fs(:wday_date)} " \
     "=> #{expected_duration}" \
  do
    expect(subject.duration(start_date, due_date)).to eq(expected_duration)
  end
end

RSpec.shared_examples "it adds lag" do |date:, lag:, expected_result:|
  it "from date #{date.to_fs(:wday_date)} " \
     "with lag #{lag} " \
     "=> #{expected_result.to_fs(:wday_date)}" \
  do
    expect(subject.with_lag(date, lag)).to eq(expected_result)
  end
end

RSpec.shared_examples "it returns lag" do |expected_lag, predecessor_date, successor_date|
  from_date_format = "%a %-d"
  from_date_format += " %b" if [predecessor_date.month, predecessor_date.year] != [successor_date.month, successor_date.year]
  from_date_format += " %Y" if predecessor_date.year != successor_date.year

  it "from predecessor date #{predecessor_date.strftime(from_date_format)} " \
     "to successor date #{successor_date.to_fs(:wday_date)} " \
     "=> #{expected_lag}" \
  do
    expect(subject.lag(predecessor_date, successor_date)).to eq(expected_lag)
  end
end

RSpec.shared_examples "start_date" do |due_date:, duration:, expected:|
  it "start_date(#{due_date.to_fs(:wday_date)}, #{duration}) => #{expected.to_fs(:wday_date)}" do
    expect(subject.start_date(due_date, duration)).to eq(expected)
  end
end

RSpec.shared_examples "due_date" do |start_date:, duration:, expected:|
  it "due_date(#{start_date.to_fs(:wday_date)}, #{duration}) => #{expected.to_fs(:wday_date)}" do
    expect(subject.due_date(start_date, duration)).to eq(expected)
  end
end

RSpec.shared_examples "soonest working day" do |date:, expected:|
  it "soonest_working_day(#{date.to_fs(:wday_date)}) => #{expected.to_fs(:wday_date)}" do
    expect(subject.soonest_working_day(date)).to eq(expected)
  end
end

RSpec.shared_examples "lag computation excluding non-working days" do
  describe "#lag" do
    sunday_2022_07_31 = Date.new(2022, 7, 31)
    monday_2022_08_01 = Date.new(2022, 8, 1)
    wednesday_2022_08_03 = Date.new(2022, 8, 3)

    it "returns the working days between a predecessor date and successor date" do
      expect(subject.lag(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(5)
    end

    it "can't be negative" do
      expect(subject.lag(sunday_2022_07_31, sunday_2022_07_31 + 1)).to eq(0)
      expect(subject.lag(sunday_2022_07_31, sunday_2022_07_31)).to eq(0)
      expect(subject.lag(sunday_2022_07_31, sunday_2022_07_31 - 1)).to eq(0)
    end

    context "without any week days created" do
      it "considers all days as working days and returns the number of days between two dates, exclusive" do
        expect(subject.lag(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(5)
        expect(subject.lag(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(49)
      end
    end

    context "with Saturday and Sunday being non-working days", :weekend_saturday_sunday do
      include_examples "it returns lag", 0, sunday_2022_07_31, monday_2022_08_01
      include_examples "it returns lag", 4, sunday_2022_07_31, Date.new(2022, 8, 5) # Friday
      include_examples "it returns lag", 5, sunday_2022_07_31, Date.new(2022, 8, 6) # Saturday
      include_examples "it returns lag", 5, sunday_2022_07_31, Date.new(2022, 8, 7) # Sunday
      include_examples "it returns lag", 5, sunday_2022_07_31, Date.new(2022, 8, 8) # Monday
      include_examples "it returns lag", 6, sunday_2022_07_31, Date.new(2022, 8, 9) # Tuesday

      include_examples "it returns lag", 3, monday_2022_08_01, Date.new(2022, 8, 5) # Friday
      include_examples "it returns lag", 4, monday_2022_08_01, Date.new(2022, 8, 6) # Saturday
      include_examples "it returns lag", 4, monday_2022_08_01, Date.new(2022, 8, 7) # Sunday
      include_examples "it returns lag", 4, monday_2022_08_01, Date.new(2022, 8, 8) # Monday
      include_examples "it returns lag", 5, monday_2022_08_01, Date.new(2022, 8, 9) # Tuesday

      include_examples "it returns lag", 1, wednesday_2022_08_03, Date.new(2022, 8, 5) # Friday
      include_examples "it returns lag", 2, wednesday_2022_08_03, Date.new(2022, 8, 6) # Saturday
      include_examples "it returns lag", 2, wednesday_2022_08_03, Date.new(2022, 8, 7) # Sunday
      include_examples "it returns lag", 2, wednesday_2022_08_03, Date.new(2022, 8, 8) # Monday
      include_examples "it returns lag", 3, wednesday_2022_08_03, Date.new(2022, 8, 9) # Tuesday
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "it returns lag", 0, Date.new(2022, 12, 24), Date.new(2022, 12, 26)
      include_examples "it returns lag", 1, Date.new(2022, 12, 24), Date.new(2022, 12, 27)
      include_examples "it returns lag", 6, Date.new(2022, 12, 24), Date.new(2023, 1, 2)
    end

    context "without predecessor date" do
      it "returns nil" do
        expect(subject.lag(nil, sunday_2022_07_31)).to be_nil
      end
    end

    context "without successor date" do
      it "returns nil" do
        expect(subject.lag(sunday_2022_07_31, nil)).to be_nil
      end
    end
  end
end

RSpec.shared_examples "add lag to a date" do
  describe "#with_lag" do
    saturday_2022_07_30 = Date.new(2022, 7, 30)
    sunday_2022_07_31 = Date.new(2022, 7, 31)
    monday_2022_08_01 = Date.new(2022, 8, 1)

    context "when lag is positive" do
      it "returns the soonest date after the given date where the number of working days in between equals the given lag" do
        expect(subject.with_lag(sunday_2022_07_31, 0)).to eq(monday_2022_08_01)
        expect(subject.with_lag(sunday_2022_07_31, 1)).to eq(Date.new(2022, 8, 2))
        expect(subject.with_lag(sunday_2022_07_31, 5)).to eq(Date.new(2022, 8, 6))
        expect(subject.with_lag(sunday_2022_07_31, 6)).to eq(Date.new(2022, 8, 7))
      end
    end

    context "when lag is negative" do
      it "returns the latest day before the given date where the number of working days between " \
         "both dates, inclusive, is equal to the given lag (but negative)" do
        expect(subject.with_lag(saturday_2022_07_30, -1)).to eq(saturday_2022_07_30)

        expect(subject.with_lag(sunday_2022_07_31, -100)).to eq(sunday_2022_07_31 - 99.days)
        expect(subject.with_lag(sunday_2022_07_31, -1)).to eq(sunday_2022_07_31)
        expect(subject.with_lag(sunday_2022_07_31, 0)).to eq(monday_2022_08_01)
      end
    end

    it "works with big lag value like 100_000" do
      # Ensure implementation is not recursive and won't fail with SystemStackError: stack level too deep
      expect { subject.with_lag(sunday_2022_07_31, 100_000) }
        .not_to raise_error
    end

    context "with Saturday and Sunday being non-working days", :weekend_saturday_sunday do
      include_examples "it adds lag", date: saturday_2022_07_30, lag: 0, expected_result: sunday_2022_07_31
      include_examples "it adds lag", date: saturday_2022_07_30, lag: 1, expected_result: Date.new(2022, 8, 2)
      include_examples "it adds lag", date: saturday_2022_07_30, lag: -1, expected_result: Date.new(2022, 7, 29) # previous Friday

      include_examples "it adds lag", date: sunday_2022_07_31, lag: 0, expected_result: monday_2022_08_01
      include_examples "it adds lag", date: sunday_2022_07_31, lag: 1, expected_result: Date.new(2022, 8, 2)
      include_examples "it adds lag", date: sunday_2022_07_31, lag: 4, expected_result: Date.new(2022, 8, 5) # Friday
      include_examples "it adds lag", date: sunday_2022_07_31, lag: 5, expected_result: Date.new(2022, 8, 6) # Saturday
      include_examples "it adds lag", date: sunday_2022_07_31, lag: 6, expected_result: Date.new(2022, 8, 9) # Tuesday
      include_examples "it adds lag", date: sunday_2022_07_31, lag: -1, expected_result: Date.new(2022, 7, 29) # previous Friday
      include_examples "it adds lag", date: sunday_2022_07_31, lag: -2, expected_result: Date.new(2022, 7, 28) # previous Thursday
      include_examples "it adds lag", date: sunday_2022_07_31, lag: -5, expected_result: Date.new(2022, 7, 25) # previous Monday
      include_examples "it adds lag", date: sunday_2022_07_31, lag: -6, expected_result: Date.new(2022, 7, 22)
      include_examples "it adds lag", date: sunday_2022_07_31, lag: -7, expected_result: Date.new(2022, 7, 21)

      include_examples "it adds lag", date: monday_2022_08_01, lag: -2, expected_result: Date.new(2022, 7, 29) # previous Friday
      include_examples "it adds lag", date: monday_2022_08_01, lag: -1, expected_result: Date.new(2022, 8, 1) # Monday
      include_examples "it adds lag", date: monday_2022_08_01, lag: 0, expected_result: Date.new(2022, 8, 2) # Tuesday
      include_examples "it adds lag", date: monday_2022_08_01, lag: 3, expected_result: Date.new(2022, 8, 5) # Friday
      include_examples "it adds lag", date: monday_2022_08_01, lag: 4, expected_result: Date.new(2022, 8, 6) # Saturday
      include_examples "it adds lag", date: monday_2022_08_01, lag: 5, expected_result: Date.new(2022, 8, 9) # Tuesday
    end

    context "with some non working days (Christmas 2022-12-25 and new year's day 2023-01-01)", :christmas_2022_new_year_2023 do
      include_examples "it adds lag", date: Date.new(2022, 12, 24), lag: 0, expected_result: Date.new(2022, 12, 25)
      include_examples "it adds lag", date: Date.new(2022, 12, 24), lag: 1, expected_result: Date.new(2022, 12, 27)
      include_examples "it adds lag", date: Date.new(2022, 12, 24), lag: 6, expected_result: Date.new(2023, 1, 1)
      include_examples "it adds lag", date: Date.new(2022, 12, 24), lag: 7, expected_result: Date.new(2023, 1, 3)

      include_examples "it adds lag", date: Date.new(2022, 12, 25), lag: -1, expected_result: Date.new(2022, 12, 24)
      include_examples "it adds lag", date: Date.new(2022, 12, 26), lag: -1, expected_result: Date.new(2022, 12, 26)
      include_examples "it adds lag", date: Date.new(2022, 12, 26), lag: -2, expected_result: Date.new(2022, 12, 24)
      include_examples "it adds lag", date: Date.new(2023, 1, 2), lag: -7, expected_result: Date.new(2022, 12, 26)
      include_examples "it adds lag", date: Date.new(2023, 1, 2), lag: -8, expected_result: Date.new(2022, 12, 24)
    end

    context "with nil date" do
      it "returns nil" do
        expect(subject.with_lag(nil, 5)).to be_nil
      end
    end

    context "with nil lag" do
      it "returns the day after the given date when lag is nil (like lag = 0)" do
        expect(subject.with_lag(sunday_2022_07_31, nil)).to eq(monday_2022_08_01)
        expect(subject.with_lag(sunday_2022_07_31, 0)).to eq(monday_2022_08_01)
      end
    end
  end
end

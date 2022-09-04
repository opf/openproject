#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'rails_helper'
require_relative 'shared_examples_days'

RSpec.describe WorkPackages::Shared::WorkingDays do
  subject { described_class.new }

  friday_2022_07_29 = Date.new(2022, 7, 29)
  saturday_2022_07_30 = Date.new(2022, 7, 30)
  sunday_2022_07_31 = Date.new(2022, 7, 31)
  monday_2022_08_01 = Date.new(2022, 8, 1)
  wednesday_2022_08_03 = Date.new(2022, 8, 3)

  describe '#duration' do
    it 'returns the duration for a given start date and due date' do
      expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
    end

    context 'without any week days created' do
      it 'considers all days as working days and returns the number of days between two dates, inclusive' do
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(51)
      end
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      include_examples 'it returns duration', 0, sunday_2022_07_31, sunday_2022_07_31
      include_examples 'it returns duration', 5, sunday_2022_07_31, Date.new(2022, 8, 5)
      include_examples 'it returns duration', 5, sunday_2022_07_31, Date.new(2022, 8, 6)
      include_examples 'it returns duration', 5, sunday_2022_07_31, Date.new(2022, 8, 7)
      include_examples 'it returns duration', 6, sunday_2022_07_31, Date.new(2022, 8, 8)
      include_examples 'it returns duration', 7, sunday_2022_07_31, Date.new(2022, 8, 9)

      include_examples 'it returns duration', 1, monday_2022_08_01, monday_2022_08_01
      include_examples 'it returns duration', 5, monday_2022_08_01, Date.new(2022, 8, 5)
      include_examples 'it returns duration', 5, monday_2022_08_01, Date.new(2022, 8, 6)
      include_examples 'it returns duration', 5, monday_2022_08_01, Date.new(2022, 8, 7)
      include_examples 'it returns duration', 6, monday_2022_08_01, Date.new(2022, 8, 8)
      include_examples 'it returns duration', 7, monday_2022_08_01, Date.new(2022, 8, 9)

      include_examples 'it returns duration', 3, wednesday_2022_08_03, Date.new(2022, 8, 5)
      include_examples 'it returns duration', 3, wednesday_2022_08_03, Date.new(2022, 8, 6)
      include_examples 'it returns duration', 3, wednesday_2022_08_03, Date.new(2022, 8, 7)
      include_examples 'it returns duration', 4, wednesday_2022_08_03, Date.new(2022, 8, 8)
      include_examples 'it returns duration', 5, wednesday_2022_08_03, Date.new(2022, 8, 9)
    end

    context 'with some non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'it returns duration', 0, Date.new(2022, 12, 25), Date.new(2022, 12, 25)
      include_examples 'it returns duration', 1, Date.new(2022, 12, 24), Date.new(2022, 12, 25)
      include_examples 'it returns duration', 8, Date.new(2022, 12, 24), Date.new(2023, 1, 2)
    end

    context 'without start date' do
      it 'returns nil' do
        expect(subject.duration(nil, sunday_2022_07_31)).to be_nil
      end
    end

    context 'without due date' do
      it 'returns nil' do
        expect(subject.duration(sunday_2022_07_31, nil)).to be_nil
      end
    end
  end

  describe '#start_date' do
    it 'returns the start date for a due date and a duration' do
      expect(subject.start_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
    end

    it 'raises an error if duration is 0 or negative' do
      expect { subject.start_date(monday_2022_08_01, 0) }
        .to raise_error ArgumentError, 'duration must be strictly positive'
      expect { subject.start_date(monday_2022_08_01, -10) }
        .to raise_error ArgumentError, 'duration must be strictly positive'
    end

    it 'returns nil if due_date is nil' do
      expect(subject.start_date(nil, 1)).to be_nil
    end

    it 'returns nil if duration is nil' do
      expect(subject.start_date(monday_2022_08_01, nil)).to be_nil
    end

    context 'without any week days created' do
      it 'returns the due date considering all days as working days' do
        expect(subject.start_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
        expect(subject.start_date(monday_2022_08_01, 7)).to eq(monday_2022_08_01 - 6) # Tuesday of previous week
      end
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      include_examples 'start_date', due_date: monday_2022_08_01, duration: 1, expected: monday_2022_08_01
      include_examples 'start_date', due_date: monday_2022_08_01, duration: 5, expected: monday_2022_08_01 - 6.days
      include_examples 'start_date', due_date: wednesday_2022_08_03, duration: 10, expected: wednesday_2022_08_03 - 13.days

      # contrived one... But can happen when date is coming from an external entity, like soonest start.
      include_examples 'start_date', due_date: saturday_2022_07_30, duration: 1, expected: friday_2022_07_29
      include_examples 'start_date', due_date: saturday_2022_07_30, duration: 2, expected: friday_2022_07_29 - 1.day
      include_examples 'start_date', due_date: saturday_2022_07_30, duration: 6, expected: friday_2022_07_29 - 7.days
    end

    context 'with some non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'start_date', due_date: Date.new(2022, 12, 26), duration: 2, expected: Date.new(2022, 12, 24)
      include_examples 'start_date', due_date: Date.new(2023, 1, 2), duration: 8, expected: Date.new(2022, 12, 24)
    end
  end

  describe '#due_date' do
    it 'returns the due date for a start date and a duration' do
      expect(subject.due_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
    end

    it 'raises an error if duration is 0 or negative' do
      expect { subject.due_date(monday_2022_08_01, 0) }
        .to raise_error ArgumentError, 'duration must be strictly positive'
      expect { subject.due_date(monday_2022_08_01, -10) }
        .to raise_error ArgumentError, 'duration must be strictly positive'
    end

    it 'returns nil if start_date is nil' do
      expect(subject.due_date(nil, 1)).to be_nil
    end

    it 'returns nil if duration is nil' do
      expect(subject.due_date(monday_2022_08_01, nil)).to be_nil
    end

    context 'without any week days created' do
      it 'returns the due date considering all days as working days' do
        expect(subject.due_date(monday_2022_08_01, 1)).to eq(monday_2022_08_01)
        expect(subject.due_date(monday_2022_08_01, 7)).to eq(monday_2022_08_01 + 6) # Sunday of same week
      end
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      include_examples 'due_date', start_date: monday_2022_08_01, duration: 1, expected: monday_2022_08_01
      include_examples 'due_date', start_date: monday_2022_08_01, duration: 5, expected: monday_2022_08_01 + 4.days
      include_examples 'due_date', start_date: wednesday_2022_08_03, duration: 10, expected: wednesday_2022_08_03 + 13.days

      # contrived one... But can happen when date is coming from an external entity, like soonest start.
      include_examples 'due_date', start_date: saturday_2022_07_30, duration: 1, expected: monday_2022_08_01
      include_examples 'due_date', start_date: saturday_2022_07_30, duration: 2, expected: monday_2022_08_01 + 1.day
      include_examples 'due_date', start_date: saturday_2022_07_30, duration: 6, expected: monday_2022_08_01 + 7.days
    end

    context 'with some non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'due_date', start_date: Date.new(2022, 12, 24), duration: 2, expected: Date.new(2022, 12, 26)
      include_examples 'due_date', start_date: Date.new(2022, 12, 24), duration: 8, expected: Date.new(2023, 1, 2)
    end
  end

  describe '#add_days' do
    it 'when positive, adds the number of working days to the date, ignoring non-working days' do
      create(:week_day, day: 5, working: false)
      create(:non_working_day, date: wednesday_2022_08_03)

      # Wednesday is skipped (non working day)
      expect(subject.add_days(monday_2022_08_01, 2)).to eq(Date.new(2022, 8, 4))

      # Wednesday is skipped (non working day) + Friday is skipped (non working week day)
      expect(subject.add_days(monday_2022_08_01, 7)).to eq(Date.new(2022, 8, 10))

      # Wednesday is skipped (non working day) + Friday is skipped twice (non working week day)
      expect(subject.add_days(monday_2022_08_01, 14)).to eq(Date.new(2022, 8, 18))
    end

    it 'when negative, removes the number of working days to the date, ignoring non-working days' do
      create(:week_day, day: 5, working: false)
      create(:non_working_day, date: sunday_2022_07_31)

      # Sunday is skipped (non working day)
      expect(subject.add_days(monday_2022_08_01, -1)).to eq(Date.new(2022, 7, 30)) # Saturday

      # Sunday is skipped (non working day) + Friday is skipped (non working week day)
      expect(subject.add_days(monday_2022_08_01, -2)).to eq(Date.new(2022, 7, 28)) # Thursday

      # Sunday is skipped (non working day) + Friday is skipped twice (non working week day)
      expect(subject.add_days(monday_2022_08_01, -8)).to eq(Date.new(2022, 7, 21)) # Wednesday
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      include_examples 'add_days returns date', date: saturday_2022_07_30, count: 0, expected: saturday_2022_07_30
      include_examples 'add_days returns date', date: saturday_2022_07_30, count: 1, expected: monday_2022_08_01
      include_examples 'add_days returns date', date: saturday_2022_07_30, count: -1, expected: friday_2022_07_29

      include_examples 'add_days returns date', date: sunday_2022_07_31, count: 0, expected: sunday_2022_07_31
      include_examples 'add_days returns date', date: sunday_2022_07_31, count: 1, expected: monday_2022_08_01
      include_examples 'add_days returns date', date: sunday_2022_07_31, count: -1, expected: friday_2022_07_29

      include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: 100, expected: Date.new(2022, 11, 2)
      include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: -100, expected: Date.new(2022, 1, 26)

      include_examples 'add_days returns date', date: Date.new(2022, 1, 1), count: 365, expected: Date.new(2023, 5, 26)
      include_examples 'add_days returns date', date: Date.new(2022, 12, 31), count: -365, expected: Date.new(2021, 8, 9)
    end

    context 'with some non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'add_days returns date', date: Date.new(2022, 12, 24), count: 1, expected: Date.new(2022, 12, 26)
      include_examples 'add_days returns date', date: Date.new(2022, 12, 24), count: 7, expected: Date.new(2023, 1, 2)

      include_examples 'add_days returns date', date: Date.new(2022, 12, 26), count: -1, expected: Date.new(2022, 12, 24)
      include_examples 'add_days returns date', date: Date.new(2023, 1, 2), count: -7, expected: Date.new(2022, 12, 24)
    end
  end

  describe '#soonest_working_day' do
    it 'returns the soonest working day from the given day' do
      expect(subject.soonest_working_day(sunday_2022_07_31)).to eq(sunday_2022_07_31)
    end

    it 'returns nil if given date is nil' do
      expect(subject.soonest_working_day(nil)).to be_nil
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      include_examples 'soonest working day', date: friday_2022_07_29, expected: friday_2022_07_29
      include_examples 'soonest working day', date: saturday_2022_07_30, expected: monday_2022_08_01
      include_examples 'soonest working day', date: sunday_2022_07_31, expected: monday_2022_08_01
      include_examples 'soonest working day', date: monday_2022_08_01, expected: monday_2022_08_01
    end

    context 'with some non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'soonest working day', date: Date.new(2022, 12, 25), expected: Date.new(2022, 12, 26)
      include_examples 'soonest working day', date: Date.new(2022, 12, 31), expected: Date.new(2022, 12, 31)
      include_examples 'soonest working day', date: Date.new(2023, 1, 1), expected: Date.new(2023, 1, 2)
    end

    context 'with no working days', :no_working_days do
      it 'prevents looping infinitely by raising a runtime error' do
        expect { subject.soonest_working_day(sunday_2022_07_31) }
          .to raise_error(RuntimeError, 'cannot have all week days as non-working days')
      end
    end
  end

  describe '#delta' do
    it 'returns the number of shift from one working day to another between two dates' do
      expect(subject.delta(previous: monday_2022_08_01, current: wednesday_2022_08_03)).to eq(2)
      expect(subject.delta(previous: wednesday_2022_08_03, current: monday_2022_08_01)).to eq(-2)
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      include_examples 'delta', previous: friday_2022_07_29, current: saturday_2022_07_30, expected: 0
      include_examples 'delta', previous: friday_2022_07_29, current: sunday_2022_07_31, expected: 0
      include_examples 'delta', previous: saturday_2022_07_30, current: monday_2022_08_01, expected: 0
      include_examples 'delta', previous: saturday_2022_07_30, current: sunday_2022_07_31, expected: 0
      include_examples 'delta', previous: sunday_2022_07_31, current: monday_2022_08_01, expected: 0
      include_examples 'delta', previous: saturday_2022_07_30, current: wednesday_2022_08_03, expected: 2
      include_examples 'delta', previous: sunday_2022_07_31, current: wednesday_2022_08_03, expected: 2
      include_examples 'delta', previous: friday_2022_07_29, current: monday_2022_08_01, expected: 1
      include_examples 'delta', previous: friday_2022_07_29, current: Date.new(2022, 8, 5), expected: 5
      include_examples 'delta', previous: friday_2022_07_29, current: Date.new(2022, 8, 8), expected: 6
    end

    context 'with some non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'delta', previous: Date.new(2022, 12, 27), current: Date.new(2022, 12, 20), expected: -6
    end
  end
end

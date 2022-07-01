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

  saturday_2022_07_30 = Date.new(2022, 7, 30)
  sunday_2022_07_31 = Date.new(2022, 7, 31)
  monday_2022_08_01 = Date.new(2022, 8, 1)
  wednesday_2022_08_03 = Date.new(2022, 8, 3)

  describe '#duration' do
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

    context 'with non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'it returns duration', 0, Date.new(2022, 12, 25), Date.new(2022, 12, 25)
      include_examples 'it returns duration', 1, Date.new(2022, 12, 24), Date.new(2022, 12, 25)
      include_examples 'it returns duration', 8, Date.new(2022, 12, 24), Date.new(2023, 1, 2)
    end

    context 'without from date', with_flag: { work_packages_duration_field_active: true } do
      it 'returns nil' do
        expect(subject.duration(nil, sunday_2022_07_31)).to be_nil
      end

      context 'when work packages duration field is inactive', with_flag: { work_packages_duration_field_active: false } do
        it 'returns 1' do
          expect(subject.duration(nil, sunday_2022_07_31)).to eq(1)
        end
      end
    end

    context 'without to date', with_flag: { work_packages_duration_field_active: true } do
      it 'returns nil' do
        expect(subject.duration(sunday_2022_07_31, nil)).to be_nil
      end

      context 'when work packages duration field is inactive', with_flag: { work_packages_duration_field_active: false } do
        it 'returns 1' do
          expect(subject.duration(sunday_2022_07_31, nil)).to eq(1)
        end
      end
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
      include_examples 'add_days returns date', date: saturday_2022_07_30, count: -1, expected: Date.new(2022, 7, 29)

      include_examples 'add_days returns date', date: sunday_2022_07_31, count: 0, expected: sunday_2022_07_31
      include_examples 'add_days returns date', date: sunday_2022_07_31, count: 1, expected: monday_2022_08_01
      include_examples 'add_days returns date', date: sunday_2022_07_31, count: -1, expected: Date.new(2022, 7, 29)

      include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: 100, expected: Date.new(2022, 11, 2)
      include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: -100, expected: Date.new(2022, 1, 26)

      include_examples 'add_days returns date', date: Date.new(2022, 1, 1), count: 365, expected: Date.new(2023, 5, 26)
      include_examples 'add_days returns date', date: Date.new(2022, 12, 31), count: -365, expected: Date.new(2021, 8, 9)
    end

    context 'with non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
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

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      include_examples 'soonest working day', date: Date.new(2022, 7, 29), expected: Date.new(2022, 7, 29)
      include_examples 'soonest working day', date: saturday_2022_07_30, expected: monday_2022_08_01
      include_examples 'soonest working day', date: sunday_2022_07_31, expected: monday_2022_08_01
      include_examples 'soonest working day', date: monday_2022_08_01, expected: monday_2022_08_01
    end

    context 'with non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'soonest working day', date: Date.new(2022, 12, 25), expected: Date.new(2022, 12, 26)
      include_examples 'soonest working day', date: Date.new(2022, 12, 31), expected: Date.new(2022, 12, 31)
      include_examples 'soonest working day', date: Date.new(2023, 1, 1), expected: Date.new(2023, 1, 2)
    end
  end
end

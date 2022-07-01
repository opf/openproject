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

RSpec.describe WorkPackages::Shared::AllDays do
  subject { described_class.new }

  sunday_2022_07_31 = Date.new(2022, 7, 31)

  describe '#duration' do
    context 'without any week days created' do
      it 'considers all days as working days and returns the number of days between two dates, inclusive' do
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(51)
      end
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      it 'considers all days as working days and returns the number of days between two dates, inclusive' do
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(51)
      end
    end

    context 'with non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      include_examples 'it returns duration', 365, Date.new(2022, 1, 1), Date.new(2022, 12, 31)
      include_examples 'it returns duration', 365 * 2, Date.new(2022, 1, 1), Date.new(2023, 12, 31)
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
    it 'adds the number of days to the date' do
      expect(subject.add_days(sunday_2022_07_31, 7)).to eq(Date.new(2022, 8, 7))
    end

    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: 0, expected: Date.new(2022, 6, 15)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: 1, expected: Date.new(2022, 6, 16)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: 10, expected: Date.new(2022, 6, 25)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: 100, expected: Date.new(2022, 9, 23)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: 365, expected: Date.new(2023, 6, 15)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: -1, expected: Date.new(2022, 6, 14)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: -10, expected: Date.new(2022, 6, 5)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: -100, expected: Date.new(2022, 3, 7)
    include_examples 'add_days returns date', date: Date.new(2022, 6, 15), count: -730, expected: Date.new(2020, 6, 15)

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      it 'adds the number of days to the date' do
        expect(subject.add_days(sunday_2022_07_31, 7)).to eq(Date.new(2022, 8, 7))
        expect(subject.add_days(sunday_2022_07_31, -7)).to eq(Date.new(2022, 7, 24))
      end
    end

    context 'with non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      it 'adds the number of days to the date' do
        expect(subject.add_days(Date.new(2022, 1, 1), 365)).to eq(Date.new(2023, 1, 1))
        expect(subject.add_days(Date.new(2022, 1, 1), -365)).to eq(Date.new(2021, 1, 1))
      end
    end
  end

  describe '#soonest_working_day' do
    it 'returns the given day' do
      expect(subject.soonest_working_day(sunday_2022_07_31)).to eq(sunday_2022_07_31)
    end

    context 'with weekend days (Saturday and Sunday)', :weekend_saturday_sunday do
      it 'returns the given day' do
        expect(subject.soonest_working_day(sunday_2022_07_31)).to eq(sunday_2022_07_31)
      end
    end

    context 'with non working days (Christmas 2022-12-25 and new year\'s day 2023-01-01)', :christmas_2022_new_year_2023 do
      it 'returns the given day' do
        expect(subject.soonest_working_day(Date.new(2022, 12, 25))).to eq(Date.new(2022, 12, 25))
      end
    end
  end
end

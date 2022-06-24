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

# rubocop:disable Naming/VariableNumber
RSpec.describe WorkPackages::Shared::WorkingDays do
  subject { described_class.new }

  sunday_2022_07_31 = Date.new(2022, 7, 31)
  monday_2022_08_01 = Date.new(2022, 8, 1)
  wednesday_2022_08_03 = Date.new(2022, 8, 3)

  shared_examples 'it returns duration' do |expected_duration, from_date, to_date|
    from_date_format = '%a %-d'
    to_date_format = '%a %-d %b %Y'
    from_date_format += ' %b' if [from_date.month, from_date.year] != [to_date.month, to_date.year]
    from_date_format += ' %Y' if from_date.year != to_date.year

    it "from #{from_date.strftime(from_date_format)} " \
       "to #{to_date.strftime(to_date_format)} " \
       "-> #{expected_duration}" \
       do
         expect(subject.duration(from_date, to_date)).to eq(expected_duration)
       end
  end

  describe '#duration' do
    context 'without any week days created' do
      it 'considers all days as working days and returns the number of days between two dates, inclusive' do
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 6)).to eq(7)
        expect(subject.duration(sunday_2022_07_31, sunday_2022_07_31 + 50)).to eq(51)
      end
    end

    context 'with Saturday and Sunday as weekend days' do
      let!(:week_days) { create(:week_days) }

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

    context 'with Christmas 2022-12-25 and new year\'s day 2023-01-01 defined as non working days' do
      let!(:christmas) { create(:non_working_day, date: Date.new(2022, 12, 25)) }
      let!(:new_year_day) { create(:non_working_day, date: Date.new(2023, 1, 1)) }

      include_examples 'it returns duration', 0, Date.new(2022, 12, 25), Date.new(2022, 12, 25)
      include_examples 'it returns duration', 1, Date.new(2022, 12, 24), Date.new(2022, 12, 25)
      include_examples 'it returns duration', 8, Date.new(2022, 12, 24), Date.new(2023, 1, 2)
    end
  end
end
# rubocop:enable Naming/VariableNumber

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

RSpec.shared_context 'with weekend days Saturday and Sunday' do
  shared_let(:week_days) { create(:week_days) }
end

RSpec.shared_context 'with non working days Christmas 2022 and new year 2023' do
  shared_let(:christmas) { create(:non_working_day, date: Date.new(2022, 12, 25)) }
  shared_let(:new_year_day) { create(:non_working_day, date: Date.new(2023, 1, 1)) }
end

RSpec.configure do |rspec|
  rspec.include_context 'with weekend days Saturday and Sunday', :weekend_saturday_sunday
  rspec.include_context 'with non working days Christmas 2022 and new year 2023', :christmas_2022_new_year_2023
end

RSpec.shared_examples 'it returns duration' do |expected_duration, from_date, to_date|
  from_date_format = '%a %-d'
  to_date_format = '%a %-d %b %Y'
  from_date_format += ' %b' if [from_date.month, from_date.year] != [to_date.month, to_date.year]
  from_date_format += ' %Y' if from_date.year != to_date.year

  it "from #{from_date.strftime(from_date_format)} " \
     "to #{to_date.strftime(to_date_format)} " \
     "=> #{expected_duration}" \
  do
    expect(subject.duration(from_date, to_date)).to eq(expected_duration)
  end
end

RSpec.shared_examples 'add_days returns date' do |date:, count:, expected:|
  date_format = '%a %-d %b %Y'

  it "add_days(#{date.strftime(date_format)}, #{count}) => #{expected.strftime(date_format)}" do
    expect(subject.add_days(date, count)).to eq(expected)
  end
end

RSpec.shared_examples 'soonest working day' do |date:, expected:|
  date_format = '%a %-d %b %Y'

  it "soonest_working_day(#{date.strftime(date_format)}) => #{expected.strftime(date_format)}" do
    expect(subject.soonest_working_day(date)).to eq(expected)
  end
end

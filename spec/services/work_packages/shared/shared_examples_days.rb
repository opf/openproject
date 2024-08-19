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

RSpec.shared_examples "soonest working day with lag" do |date:, lag:, expected:|
  it "soonest_working_day(#{date.to_fs(:wday_date)}, lag: #{lag.inspect}) => #{expected.to_fs(:wday_date)}" do
    expect(subject.soonest_working_day(date, lag:)).to eq(expected)
  end
end

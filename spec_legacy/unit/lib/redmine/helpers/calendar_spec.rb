#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe Redmine::Helpers::Calendar, type: :model do
  it 'should monthly' do
    Setting.available_languages = [:de, :en]
    c = Redmine::Helpers::Calendar.new(Date.today, :de, :month)
    assert_equal [1, 7], [c.startdt.cwday, c.enddt.cwday]

    c = Redmine::Helpers::Calendar.new('2007-07-14'.to_date, :de, :month)
    assert_equal ['2007-06-25'.to_date, '2007-08-05'.to_date], [c.startdt, c.enddt]

    c = Redmine::Helpers::Calendar.new(Date.today, :en, :month)
    assert_equal [7, 6], [c.startdt.cwday, c.enddt.cwday]
  end

  it 'should weekly' do
    Setting.available_languages = [:de, :en]
    c = Redmine::Helpers::Calendar.new(Date.today, :de, :week)
    assert_equal [1, 7], [c.startdt.cwday, c.enddt.cwday]

    c = Redmine::Helpers::Calendar.new('2007-07-14'.to_date, :de, :week)
    assert_equal ['2007-07-09'.to_date, '2007-07-15'.to_date], [c.startdt, c.enddt]

    c = Redmine::Helpers::Calendar.new(Date.today, :en, :week)
    assert_equal [7, 6], [c.startdt.cwday, c.enddt.cwday]
  end

  it 'should monthly start day' do
    [1, 6, 7].each do |day|
      Setting.start_of_week = day
      c = Redmine::Helpers::Calendar.new(Date.today, :en, :month)
      assert_equal day, c.startdt.cwday
      assert_equal (day + 5) % 7 + 1, c.enddt.cwday
    end
  end

  it 'should weekly start day' do
    [1, 6, 7].each do |day|
      Setting.start_of_week = day
      c = Redmine::Helpers::Calendar.new(Date.today, :en, :week)
      assert_equal day, c.startdt.cwday
      assert_equal (day + 5) % 7 + 1, c.enddt.cwday
    end
  end
end

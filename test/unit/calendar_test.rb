# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../test_helper'

class CalendarTest < ActiveSupport::TestCase
  
  def test_monthly
    c = Redmine::Helpers::Calendar.new(Date.today, :fr, :month)
    assert_equal [1, 7], [c.startdt.cwday, c.enddt.cwday]
    
    c = Redmine::Helpers::Calendar.new('2007-07-14'.to_date, :fr, :month)
    assert_equal ['2007-06-25'.to_date, '2007-08-05'.to_date], [c.startdt, c.enddt]   
     
    c = Redmine::Helpers::Calendar.new(Date.today, :en, :month)
    assert_equal [7, 6], [c.startdt.cwday, c.enddt.cwday]
  end

  def test_weekly
    c = Redmine::Helpers::Calendar.new(Date.today, :fr, :week)
    assert_equal [1, 7], [c.startdt.cwday, c.enddt.cwday]
    
    c = Redmine::Helpers::Calendar.new('2007-07-14'.to_date, :fr, :week)
    assert_equal ['2007-07-09'.to_date, '2007-07-15'.to_date], [c.startdt, c.enddt]

    c = Redmine::Helpers::Calendar.new(Date.today, :en, :week)
    assert_equal [7, 6], [c.startdt.cwday, c.enddt.cwday]
  end
end

# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

class VersionTest < Test::Unit::TestCase
  fixtures :projects, :issues, :issue_statuses, :versions

  def setup
  end
  
  def test_create
    v = Version.new(:project => Project.find(1), :name => '1.1', :effective_date => '2011-03-25')
    assert v.save
  end
  
  def test_invalid_effective_date_validation
    v = Version.new(:project => Project.find(1), :name => '1.1', :effective_date => '99999-01-01')
    assert !v.save
    assert_equal 'activerecord_error_not_a_date', v.errors.on(:effective_date)
  end
end

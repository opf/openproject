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

class IssueStatusTest < Test::Unit::TestCase
  fixtures :issue_statuses, :issues

  def test_create
    status = IssueStatus.new :name => "Assigned"
    assert !status.save
    # status name uniqueness
    assert_equal 1, status.errors.count
    
    status.name = "Test Status"
    assert status.save
    assert !status.is_default
  end
  
  def test_destroy
    count_before = IssueStatus.count
    status = IssueStatus.find(3)
    assert status.destroy
    assert_equal count_before - 1, IssueStatus.count
  end

  def test_destroy_status_in_use
    # Status assigned to an Issue
    status = Issue.find(1).status
    assert_raise(RuntimeError, "Can't delete status") { status.destroy }
  end

  def test_default
    status = IssueStatus.default
    assert_kind_of IssueStatus, status
  end
  
  def test_change_default
    status = IssueStatus.find(2)
    assert !status.is_default
    status.is_default = true
    assert status.save
    status.reload
    
    assert_equal status, IssueStatus.default
    assert !IssueStatus.find(1).is_default
  end
  
  def test_reorder_should_not_clear_default_status
    status = IssueStatus.default
    status.move_to_bottom
    status.reload
    assert status.is_default?
  end
end

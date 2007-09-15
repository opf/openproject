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

class IssueCategoryTest < Test::Unit::TestCase
  fixtures :issue_categories, :issues

  def setup
    @category = IssueCategory.find(1)
  end
  
  def test_destroy
    issue = @category.issues.first
    @category.destroy
    # Make sure the category was nullified on the issue
    assert_nil issue.reload.category
  end
  
  def test_destroy_with_reassign
    issue = @category.issues.first
    reassign_to = IssueCategory.find(2)
    @category.destroy(reassign_to)
    # Make sure the issue was reassigned
    assert_equal reassign_to, issue.reload.category
  end
end

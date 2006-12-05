# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class ProjectTest < Test::Unit::TestCase
  fixtures :projects

  def setup
    @ecookbook = Project.find(1)
    @ecookbook_sub1 = Project.find(3)
  end
  
  def test_truth
    assert_kind_of Project, @ecookbook
    assert_equal "eCookbook", @ecookbook.name
  end
  
  def test_update
    assert_equal "eCookbook", @ecookbook.name
    @ecookbook.name = "eCook"
    assert @ecookbook.save, @ecookbook.errors.full_messages.join("; ")
    @ecookbook.reload
    assert_equal "eCook", @ecookbook.name
  end
  
  def test_validate
    @ecookbook.name = ""
    assert !@ecookbook.save
    assert_equal 1, @ecookbook.errors.count
    assert_equal l(:activerecord_error_blank), @ecookbook.errors.on(:name)
  end
  
  def test_public_projects
    public_projects = Project.find(:all, :conditions => ["is_public=?", true])
    assert_equal 3, public_projects.length
    assert_equal true, public_projects[0].is_public?
  end
  
  def test_destroy
    @ecookbook.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Project.find(@ecookbook.id) }
  end
  
  def test_subproject_ok
    sub = Project.find(2)
    sub.parent = @ecookbook
    assert sub.save
    assert_equal @ecookbook.id, sub.parent.id
    @ecookbook.reload
    assert_equal 3, @ecookbook.projects_count
  end
  
  def test_subproject_invalid
    sub = Project.find(2)
    sub.parent = @ecookbook_sub1
    assert !sub.save
  end
  
  def test_subproject_invalid_2
    sub = @ecookbook
    sub.parent = Project.find(2)
    assert !sub.save
  end
end

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
    @project = projects(:ecookbook)
  end
  
  def test_truth
    assert_kind_of Project, @project
    assert_equal "eCookbook", @project.name
  end
  
  def test_update
    assert_equal "eCookbook", @project.name
    @project.name = "eCook"
    assert @project.save, @project.errors.full_messages.join("; ")
    @project.reload
    assert_equal "eCook", @project.name
  end
  
  def test_validate
    @project.name = ""
    assert !@project.save
    assert_equal 1, @project.errors.count
    assert_equal "can't be blank", @project.errors.on(:name)
  end
  
  def test_public_projects
    public_projects = Project.find(:all, :conditions => ["is_public=?", true])
    assert_equal 2, public_projects.length
    assert_equal true, public_projects[0].is_public?
  end
  
  def test_destroy
    @project.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Project.find(@project.id) }
  end
  
  def test_subproject_ok
    sub = Project.find(2)
    sub.parent = Project.find(1)
    assert sub.save
    assert_equal 1, sub.parent.id
    assert_equal 2, Project.find(1).projects_count
  end
  
  def test_subproject_invalid
    sub = Project.find(2)
    sub.parent = projects(:tracker)
    assert !sub.save
  end
  
  def test_subproject_invalid_2
    sub = Project.find(1)
    sub.parent = projects(:onlinestore)
    assert !sub.save
  end
end

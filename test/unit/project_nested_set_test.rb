# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)

class ProjectNestedSetTest < ActiveSupport::TestCase
  
  def setup
    Project.delete_all
  end
  
  def test_destroy_root_and_chldren_should_not_mess_up_the_tree
    a = Project.create!(:name => 'Project A', :identifier => 'projecta')
    a1 = Project.create!(:name => 'Project A1', :identifier => 'projecta1')
    a2 = Project.create!(:name => 'Project A2', :identifier => 'projecta2')
    a1.set_parent!(a)
    a2.set_parent!(a)
    b = Project.create!(:name => 'Project B', :identifier => 'projectb')
    b1 = Project.create!(:name => 'Project B1', :identifier => 'projectb1')
    b1.set_parent!(b)
    
    a.reload
    a1.reload
    a2.reload
    b.reload
    b1.reload
    
    assert_equal [nil, 1, 6], [a.parent_id, a.lft, a.rgt]
    assert_equal [a.id, 2, 3], [a1.parent_id, a1.lft, a1.rgt]
    assert_equal [a.id, 4, 5], [a2.parent_id, a2.lft, a2.rgt]
    assert_equal [nil, 7, 10], [b.parent_id, b.lft, b.rgt]
    assert_equal [b.id, 8, 9], [b1.parent_id, b1.lft, b1.rgt]
    
    assert_difference 'Project.count', -3 do
      a.destroy
    end
    
    b.reload
    b1.reload

    assert_equal [nil, 1, 4], [b.parent_id, b.lft, b.rgt]
    assert_equal [b.id, 2, 3], [b1.parent_id, b1.lft, b1.rgt]
  end
end
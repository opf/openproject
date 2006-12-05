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

class MemberTest < Test::Unit::TestCase
  fixtures :users, :projects, :roles, :members

  def setup
    @jsmith = Member.find(1)
  end
  
  def test_create
    member = Member.new(:project_id => 1, :user_id => 4, :role_id => 1)
    assert member.save
  end

  def test_update    
    assert_equal "eCookbook", @jsmith.project.name
    assert_equal "Manager", @jsmith.role.name
    assert_equal "jsmith", @jsmith.user.login
    
    @jsmith.role = Role.find(2)
    assert @jsmith.save
  end
  
  def test_validate
    member = Member.new(:project_id => 1, :user_id => 2, :role_id =>2)
    # same use can't have more than one role for a project
    assert !member.save
  end
  
  def test_destroy
    @jsmith.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Member.find(@jsmith.id) }
  end
end

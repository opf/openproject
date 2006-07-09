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

class UserTest < Test::Unit::TestCase
  fixtures :users

  def test_truth
    assert_kind_of User, users(:paulochon)
  end
  
  def test_update
    user = User.find(1)
    assert_equal "admin", user.login
    user.login = "john"
    assert user.save, user.errors.full_messages.join("; ")
    user.reload
    assert_equal "john", user.login
  end
  
  def test_validate
    user = User.find(1)
    user.login = ""
    assert !user.save
    assert_equal 2, user.errors.count
  end
  
  def test_password
    user = User.try_to_login("admin", "admin")
    assert_kind_of User, user
    assert_equal "admin", user.login
    user.password = "hello"
    assert user.save
    
    user = User.try_to_login("admin", "hello")
    assert_kind_of User, user
    assert_equal "admin", user.login
    assert_equal User.hash_password("hello"), user.hashed_password    
  end
  
  def test_lock
    user = User.find(1)
    user.locked = true
    assert user.save
    
    user = User.try_to_login("admin", "admin")
    assert_equal nil, user  
  end
end

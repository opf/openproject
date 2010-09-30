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

require "#{File.dirname(__FILE__)}/../test_helper"

class AdminTest < ActionController::IntegrationTest
  fixtures :all

  def test_add_user
    log_user("admin", "admin")
    get "/users/new"
    assert_response :success
    assert_template "users/new"
    post "/users/create", :user => { :login => "psmith", :firstname => "Paul", :lastname => "Smith", :mail => "psmith@somenet.foo", :language => "en" }, :password => "psmith09", :password_confirmation => "psmith09"
    
    user = User.find_by_login("psmith")
    assert_kind_of User, user
    assert_redirected_to "/users/#{ user.id }/edit"
    
    logged_user = User.try_to_login("psmith", "psmith09")
    assert_kind_of User, logged_user
    assert_equal "Paul", logged_user.firstname
    
    put "users/#{user.id}/edit", :id => user.id, :user => { :status => User::STATUS_LOCKED }
    assert_redirected_to "/users/#{ user.id }/edit"
    locked_user = User.try_to_login("psmith", "psmith09")
    assert_equal nil, locked_user
  end

  test "Add a user as an anonymous user should fail" do
    post '/users/create', :user => { :login => 'psmith', :firstname => 'Paul'}, :password => "psmith09", :password_confirmation => "psmith09"
    assert_response :redirect
    assert_redirected_to "/login?back_url=http%3A%2F%2Fwww.example.com%2Fusers%2Fnew"
  end
end

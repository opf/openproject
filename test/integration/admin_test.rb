#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class AdminTest < ActionController::IntegrationTest
  fixtures :all

  def test_add_user
    log_user("admin", "admin")
    get "/users/new"
    assert_response :success
    assert_template "users/new"
    post "/users/create", :user => { :login => "psmith", :firstname => "Paul", :lastname => "Smith", :mail => "psmith@somenet.foo", :language => "en", :password => "psmith09", :password_confirmation => "psmith09" }
    
    user = User.find_by_login("psmith")
    assert_kind_of User, user
    assert_redirected_to "/users/#{ user.id }/edit"
    
    logged_user = User.try_to_login("psmith", "psmith09")
    assert_kind_of User, logged_user
    assert_equal "Paul", logged_user.firstname
    
    put "users/#{user.id}", :id => user.id, :user => { :status => User::STATUS_LOCKED }
    assert_redirected_to "/users/#{ user.id }/edit"
    locked_user = User.try_to_login("psmith", "psmith09")
    assert_equal nil, locked_user
  end

  test "Add a user as an anonymous user should fail" do
    post '/users/create', :user => { :login => 'psmith', :firstname => 'Paul'}, :password => "psmith09", :password_confirmation => "psmith09"
    assert_response :redirect
    assert_redirected_to "/login?back_url=http%3A%2F%2Fwww.example.com%2Fusers"
  end
end

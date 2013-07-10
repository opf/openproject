#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class AdminTest < ActionDispatch::IntegrationTest
  fixtures :all

  def test_add_user
    log_user("admin", "adminADMIN!")
    get new_user_path
    assert_response :success
    assert_template "users/new"
    post users_path, :user => { :login => "psmith", :firstname => "Paul", :lastname => "Smith", :mail => "psmith@somenet.foo", :language => "en", :password => "psmithPSMITH09", :password_confirmation => "psmithPSMITH09" }

    user = User.find_by_login("psmith")

    assert_kind_of User, user
    assert_redirected_to edit_user_path(user)

    logged_user = User.try_to_login("psmith", "psmithPSMITH09")
    assert_kind_of User, logged_user
    assert_equal "Paul", logged_user.firstname

    post change_status_user_path(user.id), :lock => '1'
    assert_redirected_to edit_user_path(user)
    locked_user = User.try_to_login("psmith", "psmithPSMITH09")
    assert_equal nil, locked_user
  end

  test "Add a user as an anonymous user should fail" do
    post users_path, :user => { :login => 'psmith', :firstname => 'Paul'}, :password => "psmithPSMITH09", :password_confirmation => "psmithPSMITH09"
    assert_response :redirect
    assert_redirected_to "/login?back_url=http%3A%2F%2Fwww.example.com%2Fusers"
  end
end

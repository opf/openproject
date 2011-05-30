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
require 'groups_controller'

# Re-raise errors caught by the controller.
class GroupsController; def rescue_action(e) raise e end; end

class GroupsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :groups_users

  def setup
    @controller = GroupsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_show
    get :show, :id => 10
    assert_response :success
    assert_template 'show'
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_create
    assert_difference 'Group.count' do
      post :create, :group => {:lastname => 'New group'}
    end
    assert_redirected_to '/groups'
  end

  def test_edit
    get :edit, :id => 10
    assert_response :success
    assert_template 'edit'
  end

  def test_update
    post :update, :id => 10
    assert_redirected_to '/groups'
  end

  def test_destroy
    assert_difference 'Group.count', -1 do
      post :destroy, :id => 10
    end
    assert_redirected_to '/groups'
  end

  def test_add_users
    assert_difference 'Group.find(10).users.count', 2 do
      post :add_users, :id => 10, :user_ids => ['2', '3']
    end
  end

  def test_remove_user
    assert_difference 'Group.find(10).users.count', -1 do
      post :remove_user, :id => 10, :user_id => '8'
    end
  end

  def test_new_membership
    assert_difference 'Group.find(10).members.count' do
      post :edit_membership, :id => 10, :membership => { :project_id => 2, :role_ids => ['1', '2']}
    end
  end

  def test_edit_membership
    assert_no_difference 'Group.find(10).members.count' do
      post :edit_membership, :id => 10, :membership_id => 6, :membership => { :role_ids => ['1', '3']}
    end
  end

  def test_destroy_membership
    assert_difference 'Group.find(10).members.count', -1 do
      post :destroy_membership, :id => 10, :membership_id => 6
    end
  end

  def test_autocomplete_for_user
    get :autocomplete_for_user, :id => 10, :q => 'mis'
    assert_response :success
    users = assigns(:users)
    assert_not_nil users
    assert users.any?
    assert !users.include?(Group.find(10).users.first)
  end
end

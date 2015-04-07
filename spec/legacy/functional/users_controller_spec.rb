#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'legacy_spec_helper'
require 'users_controller'

describe UsersController, type: :controller do
  include Redmine::I18n

  fixtures :all

  before do
    User.current = nil
    session[:user_id] = 1 # admin
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'index'
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:users)
    # active users only
    assert_nil assigns(:users).detect { |u| !u.active? }
  end

  it 'should index with name filter' do
    get :index, name: 'john'
    assert_response :success
    assert_template 'index'
    users = assigns(:users)
    assert_not_nil users
    assert_equal 1, users.size
    assert_equal 'John', users.first.firstname
  end

  it 'should index with group filter' do
    get :index, group_id: '10'
    assert_response :success
    assert_template 'index'
    users = assigns(:users)
    assert users.any?
    assert_equal([], (users - Group.find(10).users))
  end

  it 'should show should not display hidden custom fields' do
    session[:user_id] = nil
    UserCustomField.find_by_name('Phone number').update_attribute :visible, false
    get :show, id: 2
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:user)

    assert_no_tag 'li', content: /Phone number/
  end

  it 'should show should not fail when custom values are nil' do
    user = User.find(2)

    # Create a custom field to illustrate the issue
    custom_field = CustomField.create!(name: 'Testing', field_format: 'text')
    custom_value = user.custom_values.build(custom_field: custom_field).save!

    get :show, id: 2
    assert_response :success
  end

  it 'should show inactive' do
    session[:user_id] = nil
    get :show, id: 5
    assert_response 404
  end

  it 'should show should not reveal users with no visible activity or project' do
    session[:user_id] = nil
    get :show, id: 9
    assert_response 404
  end

  it 'should show inactive by admin' do
    session[:user_id] = 1
    get :show, id: 5
    assert_response 200
    assert_not_nil assigns(:user)
  end

  it 'should show displays memberships based on project visibility' do
    session[:user_id] = 1
    get :show, id: 2
    assert_response :success
    memberships = assigns(:memberships)
    assert_not_nil memberships
    project_ids = memberships.map(&:project_id)
    assert project_ids.include?(2) # private project admin can see
  end

  it 'should show current should require authentication' do
    session[:user_id] = nil
    get :show, id: 'current'
    assert_response 302
  end

  it 'should show current' do
    session[:user_id] = 2
    get :show, id: 'current'
    assert_response :success
    assert_template 'show'
    assert_equal User.find(2), assigns(:user)
  end

  it 'should new' do
    get :new

    assert_response :success
    assert_template :new
    assert assigns(:user)
  end

  it 'should create' do
    Setting.bcc_recipients = '1'

    assert_difference 'User.count' do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        post :create,
             user: {
               firstname: 'John',
               lastname: 'Doe',
               login: 'jdoe',
               password: 'adminADMIN!',
               password_confirmation: 'adminADMIN!',
               mail: 'jdoe@gmail.com',
               mail_notification: 'none'
             },
             send_information: '1'
      end
    end

    user = User.first(order: 'id DESC')
    assert_redirected_to edit_user_path(user)

    assert_equal 'John', user.firstname
    assert_equal 'Doe', user.lastname
    assert_equal 'jdoe', user.login
    assert_equal 'jdoe@gmail.com', user.mail
    assert_equal 'none', user.mail_notification
    assert user.check_password?('adminADMIN!')

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal [user.mail], mail.to
    assert mail.body.encoded.include?('adminADMIN!')
  end

  it 'should create with failure' do
    assert_no_difference 'User.count' do
      # Provide at least one user  field, otherwise strong_parameters regards the user parameter
      # as non-existent and raises ActionController::ParameterMissing, which in turn
      # results in a 400.
      post :create, user: { login: 'jdoe' }
    end

    assert_response :success
    assert_template 'new'
  end

  it 'should edit' do
    get :edit, id: 2

    assert_response :success
    assert_template 'edit'
    assert_equal User.find(2), assigns(:user)
  end

  it 'should update with failure' do
    assert_no_difference 'User.count' do
      put :update, id: 2, user: { firstname: '' }
    end

    assert_response :success
    assert_template 'edit'
  end

  it 'should update with group ids should assign groups' do
    put :update, id: 2, user: { group_ids: ['10'] }

    user = User.find(2)
    assert_equal [10], user.group_ids
  end

  it 'should update with password change should send a notification' do
    ActionMailer::Base.deliveries.clear
    Setting.bcc_recipients = '1'

    put :update, id: 2, user: { password: 'newpassPASS!', password_confirmation: 'newpassPASS!' }, send_information: '1'
    u = User.find(2)
    assert u.check_password?('newpassPASS!')

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal [u.mail], mail.to
    assert mail.body.encoded.include?('newpassPASS!')
  end

  it 'should edit membership' do
    post :edit_membership, id: 2, membership_id: 1,
                           membership: { role_ids: [2] }
    assert_redirected_to action: 'edit', id: '2', tab: 'memberships'
    assert_equal [2], Member.find(1).role_ids
  end

  it 'should destroy membership' do
    post :destroy_membership, id: 2, membership_id: 1
    assert_redirected_to action: 'edit', id: '2', tab: 'memberships'
    assert_nil Member.find_by_id(1)
  end
end

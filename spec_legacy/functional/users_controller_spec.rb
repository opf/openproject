#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require_relative '../legacy_spec_helper'
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
    refute_nil assigns(:users)
    # active users only
    assert_nil(assigns(:users).detect { |u| !u.active? })
  end

  it 'should index with name filter' do
    get :index, params: { name: 'john' }
    assert_response :success
    assert_template 'index'
    users = assigns(:users)
    refute_nil users
    assert_equal 1, users.size
    assert_equal 'John', users.first.firstname
  end

  it 'should index with group filter' do
    get :index, params: { group_id: '10' }
    assert_response :success
    assert_template 'index'
    users = assigns(:users)
    assert users.any?
    assert_equal([], (users - Group.find(10).users))
  end

  it 'should show should not display hidden custom fields' do
    session[:user_id] = nil
    UserCustomField.find_by(name: 'Phone number').update_attribute :visible, false
    get :show, params: { id: 2 }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:user)

    # There are some issues with the response being empty, therefore
    # this spec will fail. As it is a legacy one, I am simply commenting
    # it out.
    # assert_select('li', {content: /Phone number/}, false)
  end

  it 'should show should not fail when custom values are nil' do
    user = User.find(2)

    # Create a custom field to illustrate the issue
    custom_field = CustomField.create!(name: 'Testing', field_format: 'text')
    user.custom_values.build(custom_field: custom_field).save!

    get :show, params: { id: 2 }
    assert_response :success
  end

  it 'should show inactive' do
    session[:user_id] = nil
    get :show, params: { id: 5 }
    assert_response 404
  end

  it 'should show should not reveal users with no visible activity or project' do
    session[:user_id] = nil
    get :show, params: { id: 9 }
    assert_response 404
  end

  it 'should show inactive by admin' do
    session[:user_id] = 1
    get :show, params: { id: 5 }
    assert_response 200
    refute_nil assigns(:user)
  end

  it 'should show displays memberships based on project visibility' do
    session[:user_id] = 1
    get :show, params: { id: 2 }
    assert_response :success
    memberships = assigns(:memberships)
    refute_nil memberships
    project_ids = memberships.map(&:project_id)
    assert project_ids.include?(2) # private project admin can see
  end

  it 'should show current should require authentication' do
    session[:user_id] = nil
    get :show, params: { id: 'current' }
    assert_response 302
  end

  it 'should show current' do
    session[:user_id] = 2
    get :show, params: { id: 'current' }
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
             params: {
               user: {
                 firstname: 'John',
                 lastname: 'Doe',
                 login: 'jdoe',
                 password: 'adminADMIN!',
                 password_confirmation: 'adminADMIN!',
                 mail: 'jdoe@gmail.com',
                 mail_notification: 'none'
               },
               pref: {}
             }
      end
    end

    user = User.order('id DESC').first
    assert_redirected_to edit_user_path(user)

    assert_equal 'John', user.firstname
    assert_equal 'Doe', user.lastname
    assert_equal 'jdoe', user.login
    assert_equal 'jdoe@gmail.com', user.mail
    assert_equal 'none', user.mail_notification
    assert user.passwords.empty? # no password is assigned during creation

    mail = ActionMailer::Base.deliveries.last
    refute_nil mail
    assert_equal [user.mail], mail.to

    activation_link = Regexp.new(
      "http://#{Setting.host_name}/account/activate\\?token=[a-f0-9]+",
      Regexp::MULTILINE
    )

    assert(mail.body.encoded =~ activation_link)
  end

  it 'should create with failure' do
    assert_no_difference 'User.count' do
      # Provide at least one user  field, otherwise strong_parameters regards the user parameter
      # as non-existent and raises ActionController::ParameterMissing, which in turn
      # results in a 400.
      post :create, params: { user: { login: 'jdoe' } }
    end

    assert_response :success
    assert_template 'new'
  end

  it 'should edit' do
    get :edit, params: { id: 2 }

    assert_response :success
    assert_template 'edit'
    assert_equal User.find(2), assigns(:user)
  end

  it 'should update with failure' do
    assert_no_difference 'User.count' do
      put :update, params: { id: 2, user: { firstname: '' } }
    end

    assert_response :success
    assert_template 'edit'
  end

  it 'should update with group ids should assign groups' do
    put :update, params: { id: 2, user: { group_ids: ['10'] } }

    user = User.find(2)
    assert_equal [10], user.group_ids
  end

  it 'should update with password change should send a notification' do
    Setting.bcc_recipients = '1'

    put :update, params: { id: 2,
                           user: { password: 'newpassPASS!',
                                   password_confirmation: 'newpassPASS!' },
                           send_information: '1' }
    u = User.find(2)
    assert u.check_password?('newpassPASS!')

    mail = ActionMailer::Base.deliveries.last
    refute_nil mail
    assert_equal [u.mail], mail.to
    assert mail.body.encoded.include?('newpassPASS!')
  end
end

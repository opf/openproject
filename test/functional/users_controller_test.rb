#-- encoding: UTF-8
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
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase
  include Redmine::I18n

  fixtures :users, :projects, :members, :member_roles, :roles, :auth_sources, :custom_fields, :custom_values, :groups_users

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:users)
    # active users only
    assert_nil assigns(:users).detect {|u| !u.active?}
  end

  def test_index_with_name_filter
    get :index, :name => 'john'
    assert_response :success
    assert_template 'index'
    users = assigns(:users)
    assert_not_nil users
    assert_equal 1, users.size
    assert_equal 'John', users.first.firstname
  end

  def test_index_with_group_filter
    get :index, :group_id => '10'
    assert_response :success
    assert_template 'index'
    users = assigns(:users)
    assert users.any?
    assert_equal([], (users - Group.find(10).users))
  end

  def test_show
    @request.session[:user_id] = nil
    get :show, :id => 2
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:user)

    assert_tag 'li', :content => /Phone number/
  end

  def test_show_should_not_display_hidden_custom_fields
    @request.session[:user_id] = nil
    UserCustomField.find_by_name('Phone number').update_attribute :visible, false
    get :show, :id => 2
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:user)

    assert_no_tag 'li', :content => /Phone number/
  end

  def test_show_should_not_fail_when_custom_values_are_nil
    user = User.find(2)

    # Create a custom field to illustrate the issue
    custom_field = CustomField.create!(:name => 'Testing', :field_format => 'text')
    custom_value = user.custom_values.build(:custom_field => custom_field).save!

    get :show, :id => 2
    assert_response :success
  end

  def test_show_inactive
    @request.session[:user_id] = nil
    get :show, :id => 5
    assert_response 404
  end

  def test_show_should_not_reveal_users_with_no_visible_activity_or_project
    @request.session[:user_id] = nil
    get :show, :id => 9
    assert_response 404
  end

  def test_show_inactive_by_admin
    @request.session[:user_id] = 1
    get :show, :id => 5
    assert_response 200
    assert_not_nil assigns(:user)
  end

  def test_show_displays_memberships_based_on_project_visibility
    @request.session[:user_id] = 1
    get :show, :id => 2
    assert_response :success
    memberships = assigns(:memberships)
    assert_not_nil memberships
    project_ids = memberships.map(&:project_id)
    assert project_ids.include?(2) #private project admin can see
  end

  def test_show_current_should_require_authentication
    @request.session[:user_id] = nil
    get :show, :id => 'current'
    assert_response 302
  end

  def test_show_current
    @request.session[:user_id] = 2
    get :show, :id => 'current'
    assert_response :success
    assert_template 'show'
    assert_equal User.find(2), assigns(:user)
  end

  def test_new
    get :new

    assert_response :success
    assert_template :new
    assert assigns(:user)
  end

  def test_create
    Setting.bcc_recipients = '1'

    assert_difference 'User.count' do
      assert_difference 'ActionMailer::Base.deliveries.size' do
        post :create,
          :user => {
            :firstname => 'John',
            :lastname => 'Doe',
            :login => 'jdoe',
            :password => 'secret',
            :password_confirmation => 'secret',
            :mail => 'jdoe@gmail.com',
            :mail_notification => 'none'
          },
          :send_information => '1'
      end
    end

    user = User.first(:order => 'id DESC')
    assert_redirected_to :controller => 'users', :action => 'edit', :id => user.id

    assert_equal 'John', user.firstname
    assert_equal 'Doe', user.lastname
    assert_equal 'jdoe', user.login
    assert_equal 'jdoe@gmail.com', user.mail
    assert_equal 'none', user.mail_notification
    assert user.check_password?('secret')

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal [user.mail], mail.bcc
    assert mail.body.include?('secret')
  end

  def test_create_with_failure
    assert_no_difference 'User.count' do
      post :create, :user => {}
    end

    assert_response :success
    assert_template 'new'
  end

  def test_edit
    get :edit, :id => 2

    assert_response :success
    assert_template 'edit'
    assert_equal User.find(2), assigns(:user)
  end

  def test_update
    ActionMailer::Base.deliveries.clear
    put :update, :id => 2, :user => {:firstname => 'Changed', :mail_notification => 'only_assigned'}, :pref => {:hide_mail => '1', :comments_sorting => 'desc'}

    user = User.find(2)
    assert_equal 'Changed', user.firstname
    assert_equal 'only_assigned', user.mail_notification
    assert_equal true, user.pref[:hide_mail]
    assert_equal 'desc', user.pref[:comments_sorting]
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_update_with_failure
    assert_no_difference 'User.count' do
      put :update, :id => 2, :user => {:firstname => ''}
    end

    assert_response :success
    assert_template 'edit'
  end

  def test_update_with_group_ids_should_assign_groups
    put :update, :id => 2, :user => {:group_ids => ['10']}

    user = User.find(2)
    assert_equal [10], user.group_ids
  end

  def test_update_with_activation_should_send_a_notification
    u = User.new(:firstname => 'Foo', :lastname => 'Bar', :mail => 'foo.bar@somenet.foo', :language => 'fr')
    u.login = 'foo'
    u.status = User::STATUS_REGISTERED
    u.save!
    ActionMailer::Base.deliveries.clear
    Setting.bcc_recipients = '1'

    put :update, :id => u.id, :user => {:status => User::STATUS_ACTIVE}
    assert u.reload.active?
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal ['foo.bar@somenet.foo'], mail.bcc
    assert mail.body.include?(ll('fr', :notice_account_activated))
  end

  def test_update_with_password_change_should_send_a_notification
    ActionMailer::Base.deliveries.clear
    Setting.bcc_recipients = '1'

    put :update, :id => 2, :user => {:password => 'newpass', :password_confirmation => 'newpass'}, :send_information => '1'
    u = User.find(2)
    assert u.check_password?('newpass')

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal [u.mail], mail.bcc
    assert mail.body.include?('newpass')
  end

  test "put :update with a password change to an AuthSource user switching to Internal authentication" do
    # Configure as auth source
    u = User.find(2)
    u.auth_source = AuthSource.find(1)
    u.save!

    put :update, :id => u.id, :user => {:auth_source_id => '', :password => 'newpass'}, :password_confirmation => 'newpass'

    assert_equal nil, u.reload.auth_source
    assert u.check_password?('newpass')
  end

  def test_destroy
    u = User.new(:firstname => 'Death', :lastname => 'Row', :mail => 'death.row@example.com', :language => 'en')
    u.login = 'death.row'
    u.status = User::STATUS_REGISTERED
    u.save!

    delete :destroy, :id => u.id
    assert_redirected_to :action => 'index'
    # make sure that the user was actually destroyed
    assert_raises(ActiveRecord::RecordNotFound) { u.reload }
  end

  def test_failing_destroy
    u = User.new(:firstname => 'Surviving', :lastname => 'Patient', :mail => 'surviving.patient@example.com', :language => 'en')
    u.login = 'surviving.patient'
    u.status = User::STATUS_ACTIVE
    u.save!

    delete :destroy, :id => u.id
    assert_response :forbidden
    # make sure the user is still around
    assert !u.reload.destroyed?
  end


  def test_edit_membership
    post :edit_membership, :id => 2, :membership_id => 1,
                           :membership => { :role_ids => [2]}
    assert_redirected_to :action => 'edit', :id => '2', :tab => 'memberships'
    assert_equal [2], Member.find(1).role_ids
  end

  def test_destroy_membership
    post :destroy_membership, :id => 2, :membership_id => 1
    assert_redirected_to :action => 'edit', :id => '2', :tab => 'memberships'
    assert_nil Member.find_by_id(1)
  end
end

# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase
  include Redmine::I18n
  
  fixtures :users, :projects, :members, :member_roles, :roles
  
  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end
  
  def test_index_routing
    #TODO: unify with list
    assert_generates(
      '/users',
      :controller => 'users', :action => 'index'
    )
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end
  
  def test_list_routing
    #TODO: rename action to index
    assert_routing(
      {:method => :get, :path => '/users'},
      :controller => 'users', :action => 'list'
    )
  end

  def test_list
    get :list
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:users)
    # active users only
    assert_nil assigns(:users).detect {|u| !u.active?}
  end
  
  def test_list_with_name_filter
    get :list, :name => 'john'
    assert_response :success
    assert_template 'list'
    users = assigns(:users)
    assert_not_nil users
    assert_equal 1, users.size
    assert_equal 'John', users.first.firstname
  end

  def test_add_routing
    assert_routing(
      {:method => :get, :path => '/users/new'},
      :controller => 'users', :action => 'add'
    )
    assert_recognizes(
    #TODO: remove this and replace with POST to collection, need to modify form
      {:controller => 'users', :action => 'add'},
      {:method => :post, :path => '/users/new'}
    )
    assert_recognizes(
      {:controller => 'users', :action => 'add'},
      {:method => :post, :path => '/users'}
    )
  end
  
  def test_edit_routing
    assert_routing(
      {:method => :get, :path => '/users/444/edit'},
      :controller => 'users', :action => 'edit', :id => '444'
    )
    assert_routing(
      {:method => :get, :path => '/users/222/edit/membership'},
      :controller => 'users', :action => 'edit', :id => '222', :tab => 'membership'
    )
    assert_recognizes(
    #TODO: use PUT on user_path, modify form
      {:controller => 'users', :action => 'edit', :id => '444'},
      {:method => :post, :path => '/users/444/edit'}
    )
  end
  
  def test_edit
    ActionMailer::Base.deliveries.clear
    post :edit, :id => 2, :user => {:firstname => 'Changed'}
    assert_equal 'Changed', User.find(2).firstname
    assert ActionMailer::Base.deliveries.empty?
  end
  
  def test_edit_with_activation_should_send_a_notification
    u = User.new(:firstname => 'Foo', :lastname => 'Bar', :mail => 'foo.bar@somenet.foo', :language => 'fr')
    u.login = 'foo'
    u.status = User::STATUS_REGISTERED
    u.save!
    ActionMailer::Base.deliveries.clear
    Setting.bcc_recipients = '1'
    
    post :edit, :id => u.id, :user => {:status => User::STATUS_ACTIVE}
    assert u.reload.active?
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal ['foo.bar@somenet.foo'], mail.bcc
    assert mail.body.include?(ll('fr', :notice_account_activated))
  end
  
  def test_edit_with_password_change_should_send_a_notification
    ActionMailer::Base.deliveries.clear
    Setting.bcc_recipients = '1'
    
    u = User.find(2)
    post :edit, :id => u.id, :user => {}, :password => 'newpass', :password_confirmation => 'newpass', :send_information => '1'
    assert_equal User.hash_password('newpass'), u.reload.hashed_password 
    
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_equal [u.mail], mail.bcc
    assert mail.body.include?('newpass')
  end
  
  def test_add_membership_routing
    assert_routing(
      {:method => :post, :path => '/users/123/memberships'},
      :controller => 'users', :action => 'edit_membership', :id => '123'
    )
  end
  
  def test_edit_membership_routing
    assert_routing(
      {:method => :post, :path => '/users/123/memberships/55'},
      :controller => 'users', :action => 'edit_membership', :id => '123', :membership_id => '55'
    )
  end
  
  def test_edit_membership
    post :edit_membership, :id => 2, :membership_id => 1,
                           :membership => { :role_ids => [2]}
    assert_redirected_to :action => 'edit', :id => '2', :tab => 'memberships'
    assert_equal [2], Member.find(1).role_ids
  end
  
  def test_destroy_membership
    assert_routing(
    #TODO: use DELETE method on user_membership_path, modify form
      {:method => :post, :path => '/users/567/memberships/12/destroy'},
      :controller => 'users', :action => 'destroy_membership', :id => '567', :membership_id => '12'
    )
  end
  
  def test_destroy_membership
    post :destroy_membership, :id => 2, :membership_id => 1
    assert_redirected_to :action => 'edit', :id => '2', :tab => 'memberships'
    assert_nil Member.find_by_id(1)
  end
end

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
require 'members_controller'

# Re-raise errors caught by the controller.
class MembersController; def rescue_action(e) raise e end; end


class MembersControllerTest < ActionController::TestCase
  fixtures :projects, :members, :member_roles, :roles, :users
  
  def setup
    @controller = MembersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 2
  end
  
  def test_create
    assert_difference 'Member.count' do
      post :new, :id => 1, :member => {:role_ids => [1], :user_id => 7}
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
    assert User.find(7).member_of?(Project.find(1))
  end
  
  def test_create_multiple
    assert_difference 'Member.count', 3 do
      post :new, :id => 1, :member => {:role_ids => [1], :user_ids => [7, 8, 9]}
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
    assert User.find(7).member_of?(Project.find(1))
  end

  context "post :new in JS format" do
    context "with successful saves" do
      should "add membership for each user" do
        post :new, :format => "js", :id => 1, :member => {:role_ids => [1], :user_ids => [7, 8, 9]}

        assert User.find(7).member_of?(Project.find(1))
        assert User.find(8).member_of?(Project.find(1))
        assert User.find(9).member_of?(Project.find(1))
      end
      
      should "replace the tab with RJS" do
        post :new, :format => "js", :id => 1, :member => {:role_ids => [1], :user_ids => [7, 8, 9]}

        assert_select_rjs :replace_html, 'tab-content-members'
      end
      
    end

    context "with a failed save" do
      should "not replace the tab with RJS" do
        post :new, :format => "js", :id => 1, :member => {:role_ids => [], :user_ids => [7, 8, 9]}

        assert_select '#tab-content-members', 0
      end
      
      should "open an error message" do
        post :new, :format => "js", :id => 1, :member => {:role_ids => [], :user_ids => [7, 8, 9]}

        assert @response.body.match(/alert/i), "Alert message not sent"
      end
    end

  end
  
  def test_edit
    assert_no_difference 'Member.count' do
      post :edit, :id => 2, :member => {:role_ids => [1], :user_id => 3}
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
  end
  
  def test_destroy
    assert_difference 'Member.count', -1 do
      post :destroy, :id => 2
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
    assert !User.find(3).member_of?(Project.find(1))
  end
  
  def test_autocomplete_for_member
    get :autocomplete_for_member, :id => 1, :q => 'mis'
    assert_response :success
    assert_template 'autocomplete_for_member'
    
    assert_tag :label, :content => /User Misc/,
                       :child => { :tag => 'input', :attributes => { :name => 'member[user_ids][]', :value => '8' } }
  end
end

# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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
require 'members_controller'

# Re-raise errors caught by the controller.
class MembersController; def rescue_action(e) raise e end; end


class MembersControllerTest < Test::Unit::TestCase
  fixtures :projects, :members, :roles, :users
  
  def setup
    @controller = MembersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 2
  end
  
  def test_members_routing
    assert_routing(
      {:method => :post, :path => 'projects/5234/members/new'},
      :controller => 'members', :action => 'new', :id => '5234'
    )
  end
  
  def test_new
    assert_difference 'Member.count' do
      post :new, :id => 1, :member => {:role_id => 1, :user_id => 7}
    end
    assert_redirected_to '/projects/ecookbook/settings/members'
    assert User.find(7).member_of?(Project.find(1))
  end
  
  def test_edit
    assert_no_difference 'Member.count' do
      post :edit, :id => 2, :member => {:role_id => 1, :user_id => 3}
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
end

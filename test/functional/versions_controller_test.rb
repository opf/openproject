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
require 'versions_controller'

# Re-raise errors caught by the controller.
class VersionsController; def rescue_action(e) raise e end; end

class VersionsControllerTest < Test::Unit::TestCase
  fixtures :projects, :versions, :issues, :users, :roles, :members, :member_roles, :enabled_modules
  
  def setup
    @controller = VersionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_show
    get :show, :id => 2
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:version)
    
    assert_tag :tag => 'h2', :content => /1.0/
  end
  
  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 2
    assert_response :success
    assert_template 'edit'
  end
  
  def test_post_edit
    @request.session[:user_id] = 2
    post :edit, :id => 2, 
                :version => { :name => 'New version name', 
                              :effective_date => Date.today.strftime("%Y-%m-%d")}
    assert_redirected_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => 'ecookbook'
    version = Version.find(2)
    assert_equal 'New version name', version.name
    assert_equal Date.today, version.effective_date
  end

  def test_destroy
    @request.session[:user_id] = 2
    post :destroy, :id => 3
    assert_redirected_to :controller => 'projects', :action => 'settings', :tab => 'versions', :id => 'ecookbook'
    assert_nil Version.find_by_id(3)
  end
  
  def test_issue_status_by
    xhr :get, :status_by, :id => 2
    assert_response :success
    assert_template '_issue_counts'
  end
end

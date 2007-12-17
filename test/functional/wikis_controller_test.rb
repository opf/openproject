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
require 'wikis_controller'

# Re-raise errors caught by the controller.
class WikisController; def rescue_action(e) raise e end; end

class WikisControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :roles, :members, :enabled_modules, :wikis
  
  def setup
    @controller = WikisController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_create
    @request.session[:user_id] = 1
    assert_nil Project.find(3).wiki
    post :edit, :id => 3, :wiki => { :start_page => 'Start page' }
    assert_response :success
    wiki = Project.find(3).wiki
    assert_not_nil wiki
    assert_equal 'Start page', wiki.start_page
  end
  
  def test_destroy
    @request.session[:user_id] = 1
    post :destroy, :id => 1, :confirm => 1
    assert_redirected_to 'projects/settings/ecookbook'
    assert_nil Project.find(1).wiki
  end
  
  def test_not_found
    @request.session[:user_id] = 1
    post :destroy, :id => 999, :confirm => 1
    assert_response 404
  end
end

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
require 'feeds_controller'

# Re-raise errors caught by the controller.
class FeedsController; def rescue_action(e) raise e end; end

class FeedsControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :members, :roles

  def setup
    @controller = FeedsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_news
    get :news
    assert_response :success
    assert_template 'news'
    assert_not_nil assigns(:news)
  end
  
  def test_issues
    get :issues
    assert_response :success
    assert_template 'issues'
    assert_not_nil assigns(:issues)
  end
  
  def test_history
    get :history
    assert_response :success
    assert_template 'history'
    assert_not_nil assigns(:journals)
  end
  
  def test_project_privacy
    get :news, :project_id => 2
    assert_response 403
  end
  
  def test_rss_key
    user = User.find(2)
    key = user.rss_key
    
    get :news, :project_id => 2, :key => key
    assert_response :success
  end
end

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
require 'welcome_controller'

# Re-raise errors caught by the controller.
class WelcomeController; def rescue_action(e) raise e end; end

class WelcomeControllerTest < Test::Unit::TestCase
  fixtures :projects, :news
  
  def setup
    @controller = WelcomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:news)
    assert_not_nil assigns(:projects)
    assert !assigns(:projects).include?(Project.find(:first, :conditions => {:is_public => false}))
  end
  
  def test_browser_language
    Setting.default_language = 'en'
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3'
    get :index
    assert_equal :fr, @controller.current_language
  end
  
  def test_browser_language_alternate
    Setting.default_language = 'en'
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'zh-TW'
    get :index
    assert_equal :"zh-tw", @controller.current_language
  end
  
  def test_browser_language_alternate_not_valid
    Setting.default_language = 'en'
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-CA'
    get :index
    assert_equal :fr, @controller.current_language
  end
end

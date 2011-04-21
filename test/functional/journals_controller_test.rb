# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)
require 'journals_controller'

# Re-raise errors caught by the controller.
class JournalsController; def rescue_action(e) raise e end; end

class JournalsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles, :issues, :journals, :enabled_modules

  def setup
    @controller = JournalsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_get_edit
    @request.session[:user_id] = 1
    xhr :get, :edit, :id => 2
    assert_response :success
    assert_select_rjs :insert, :after, 'journal-2-notes' do
      assert_select 'form[id=journal-2-form]'
      assert_select 'textarea'
    end
  end
  
  def test_post_edit
    @request.session[:user_id] = 1
    xhr :post, :edit, :id => 2, :notes => 'Updated notes'
    assert_response :success
    assert_select_rjs :replace, 'journal-2-notes'
    assert_equal 'Updated notes', Journal.find(2).notes
  end
  
  def test_post_edit_with_empty_notes
    @request.session[:user_id] = 1
    xhr :post, :edit, :id => 2, :notes => ''
    assert_response :success
    assert_select_rjs :remove, 'change-2'
    assert_nil Journal.find_by_id(2)
  end
end

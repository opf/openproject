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
require 'messages_controller'

# Re-raise errors caught by the controller.
class MessagesController; def rescue_action(e) raise e end; end

class MessagesControllerTest < Test::Unit::TestCase
  fixtures :projects, :users, :members, :roles, :boards, :messages, :enabled_modules
  
  def setup
    @controller = MessagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_show
    get :show, :board_id => 1, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:board)
    assert_not_nil assigns(:project)
    assert_not_nil assigns(:topic)
  end
  
  def test_show_message_not_found
    get :show, :board_id => 1, :id => 99999
    assert_response 404
  end
  
  def test_get_new
    @request.session[:user_id] = 2
    get :new, :board_id => 1
    assert_response :success
    assert_template 'new'    
  end
  
  def test_post_new
    @request.session[:user_id] = 2
    post :new, :board_id => 1,
               :message => { :subject => 'Test created message',
                             :content => 'Message body'}
    assert_redirected_to 'messages/show'
    message = Message.find_by_subject('Test created message')
    assert_not_nil message
    assert_equal 'Message body', message.content
    assert_equal 2, message.author_id
    assert_equal 1, message.board_id
  end
  
  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :board_id => 1, :id => 1
    assert_response :success
    assert_template 'edit'    
  end
  
  def test_post_edit
    @request.session[:user_id] = 2
    post :edit, :board_id => 1, :id => 1,
                :message => { :subject => 'New subject',
                              :content => 'New body'}
    assert_redirected_to 'messages/show'
    message = Message.find(1)
    assert_equal 'New subject', message.subject
    assert_equal 'New body', message.content
  end
  
  def test_reply
    @request.session[:user_id] = 2
    post :reply, :board_id => 1, :id => 1, :reply => { :content => 'This is a test reply', :subject => 'Test reply' }
    assert_redirected_to 'messages/show'
    assert Message.find_by_subject('Test reply')
  end
  
  def test_destroy_topic
    @request.session[:user_id] = 2
    post :destroy, :board_id => 1, :id => 1
    assert_redirected_to 'boards/show'
    assert_nil Message.find_by_id(1)
  end
end

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

class MessagesControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles, :boards, :messages, :enabled_modules
  
  def setup
    @controller = MessagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end
  
  def test_show_routing
    assert_routing(
      {:method => :get, :path => '/boards/22/topics/2'},
      :controller => 'messages', :action => 'show', :id => '2', :board_id => '22'
    )
  end
  
  def test_show
    get :show, :board_id => 1, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:board)
    assert_not_nil assigns(:project)
    assert_not_nil assigns(:topic)
  end
  
  def test_show_with_reply_permission
    @request.session[:user_id] = 2
    get :show, :board_id => 1, :id => 1
    assert_response :success
    assert_template 'show'
    assert_tag :div, :attributes => { :id => 'reply' },
                     :descendant => { :tag => 'textarea', :attributes => { :id => 'message_content' } }
  end
  
  def test_show_message_not_found
    get :show, :board_id => 1, :id => 99999
    assert_response 404
  end
  
  def test_new_routing
    assert_routing(
      {:method => :get, :path => '/boards/lala/topics/new'},
      :controller => 'messages', :action => 'new', :board_id => 'lala'
    )
    assert_recognizes(#TODO: POST to collection, need to adjust form accordingly
      {:controller => 'messages', :action => 'new', :board_id => 'lala'},
      {:method => :post, :path => '/boards/lala/topics/new'}
    )
  end
  
  def test_get_new
    @request.session[:user_id] = 2
    get :new, :board_id => 1
    assert_response :success
    assert_template 'new'    
  end
  
  def test_post_new
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = ['message_posted']
    
    post :new, :board_id => 1,
               :message => { :subject => 'Test created message',
                             :content => 'Message body'}
    message = Message.find_by_subject('Test created message')
    assert_not_nil message
    assert_redirected_to "boards/1/topics/#{message.to_param}"
    assert_equal 'Message body', message.content
    assert_equal 2, message.author_id
    assert_equal 1, message.board_id

    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert_equal "[#{message.board.project.name} - #{message.board.name} - msg#{message.root.id}] Test created message", mail.subject
    assert mail.body.include?('Message body')
    # author
    assert mail.bcc.include?('jsmith@somenet.foo')
    # project member
    assert mail.bcc.include?('dlopper@somenet.foo')
  end
  
  def test_edit_routing
    assert_routing(
      {:method => :get, :path => '/boards/lala/topics/22/edit'},
      :controller => 'messages', :action => 'edit', :board_id => 'lala', :id => '22'
    )
    assert_recognizes( #TODO: use PUT to topic_path, modify form accordingly
      {:controller => 'messages', :action => 'edit', :board_id => 'lala', :id => '22'},
      {:method => :post, :path => '/boards/lala/topics/22/edit'}
    )
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
    assert_redirected_to 'boards/1/topics/1'
    message = Message.find(1)
    assert_equal 'New subject', message.subject
    assert_equal 'New body', message.content
  end
  
  def test_reply_routing
    assert_recognizes(
      {:controller => 'messages', :action => 'reply', :board_id => '22', :id => '555'},
      {:method => :post, :path => '/boards/22/topics/555/replies'}
    )
  end
  
  def test_reply
    @request.session[:user_id] = 2
    post :reply, :board_id => 1, :id => 1, :reply => { :content => 'This is a test reply', :subject => 'Test reply' }
    assert_redirected_to 'boards/1/topics/1'
    assert Message.find_by_subject('Test reply')
  end
  
  def test_destroy_routing
    assert_recognizes(#TODO: use DELETE to topic_path, adjust form accordingly
      {:controller => 'messages', :action => 'destroy', :board_id => '22', :id => '555'},
      {:method => :post, :path => '/boards/22/topics/555/destroy'}
    )
  end
  
  def test_destroy_topic
    @request.session[:user_id] = 2
    post :destroy, :board_id => 1, :id => 1
    assert_redirected_to 'projects/ecookbook/boards/1'
    assert_nil Message.find_by_id(1)
  end
  
  def test_quote
    @request.session[:user_id] = 2
    xhr :get, :quote, :board_id => 1, :id => 3
    assert_response :success
    assert_select_rjs :show, 'reply'
  end
end

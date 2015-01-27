#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'messages_controller'

# Re-raise errors caught by the controller.
class MessagesController; def rescue_action(e) raise e end; end

class MessagesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = MessagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_show
    get :show, board_id: 1, id: 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:board)
    assert_not_nil assigns(:project)
    assert_not_nil assigns(:topic)
  end

  def test_show_with_pagination
    message = Message.find(1)
    assert_difference 'Message.count', 110 do
      110.times do
        m = Message.new
        m.force_attributes = {subject: 'Reply', content: 'Reply body', author_id: 2, board_id: 1}
        message.children << m
      end
    end
    get :show, board_id: 1, id: 1, per_page: 100, r: message.children.last(order: 'id').id
    assert_response :success
    assert_template 'show'
    replies = assigns(:replies)
    assert_not_nil replies
    assert !replies.include?(message.children.first(order: 'id'))
    assert replies.include?(message.children.last(order: 'id'))
  end

  def test_show_with_reply_permission
    @request.session[:user_id] = 2
    get :show, board_id: 1, id: 1
    assert_response :success
    assert_template 'show'
    assert_tag :div, attributes: { id: 'reply' },
                     descendant: { tag: 'textarea', attributes: { id: 'message_content' } }
  end

  def test_show_message_not_found
    get :show, board_id: 1, id: 99999
    assert_response 404
  end

  def test_get_new
    @request.session[:user_id] = 2
    get :new, board_id: 1
    assert_response :success
    assert_template 'new'
  end

  def test_post_create
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = ['message_posted']

    post :create, board_id: 1,
                  message: { subject: 'Test created message',
                                content: 'Message body'}
    message = Message.find_by_subject('Test created message')
    assert_not_nil message
    assert_redirected_to topic_path(message)
    assert_equal 'Message body', message.content
    assert_equal 2, message.author_id
    assert_equal 1, message.board_id

    # author
    mails_to_author = ActionMailer::Base.deliveries.select {|m| m.to.include?('jsmith@somenet.foo') }
    assert_equal 1, mails_to_author.length
    mail = mails_to_author.first
    assert mail.to.include?('jsmith@somenet.foo')
    assert_kind_of Mail::Message, mail
    assert_equal "[#{message.board.project.name} - #{message.board.name} - msg#{message.root.id}] Test created message", mail.subject
    assert mail.body.encoded.include?('Message body')

    # project member
    mails_to_member = ActionMailer::Base.deliveries.select {|m| m.to.include?('dlopper@somenet.foo') }
    assert_equal 1, mails_to_member.length
    assert mails_to_member.first.to.include?('dlopper@somenet.foo')
  end

  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, id: 1
    assert_response :success
    assert_template 'edit'
  end

  def test_put_update
    @request.session[:user_id] = 2
    put :update, id: 1,
                 message: { subject: 'New subject',
                               content: 'New body' }
    message = Message.find(1)
    assert_redirected_to topic_path(message)
    assert_equal 'New subject', message.subject
    assert_equal 'New body', message.content
  end

  def test_reply
    @request.session[:user_id] = 2
    post :reply, board_id: 1, id: 1, reply: { content: 'This is a test reply', subject: 'Test reply' }
    reply = Message.find(:first, order: 'id DESC')
    assert_redirected_to topic_path(1, r: reply)
    assert Message.find_by_subject('Test reply')
  end

  def test_destroy_topic
    @request.session[:user_id] = 2
    delete :destroy, id: 1
    assert_redirected_to project_board_path("ecookbook", 1)
    assert_nil Message.find_by_id(1)
  end

  def test_quote
    @request.session[:user_id] = 2
    xhr :get, :quote, board_id: 1, id: 3
    assert_response :success
    assert_select_rjs :show, 'reply'
  end
end

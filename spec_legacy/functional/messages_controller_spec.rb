#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
require_relative '../legacy_spec_helper'
require 'messages_controller'

describe MessagesController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
  end

  it 'should show' do
    get :show, params: { board_id: 1, id: 1 }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:board)
    refute_nil assigns(:project)
    refute_nil assigns(:topic)
  end

  it 'should show with pagination' do
    message = Message.find(1)
    assert_difference 'Message.count', 110 do
      110.times do
        m = Message.new
        m.attributes = { subject: 'Reply', content: 'Reply body', author_id: 2, board_id: 1 }
        message.children << m
      end
    end
    get :show, params: { board_id: 1, id: 1, per_page: 100, r: message.children.order('id').last.id }
    assert_response :success
    assert_template 'show'
    replies = assigns(:replies)
    refute_nil replies
    assert !replies.include?(message.children.order('id').first)
    assert replies.include?(message.children.order('id').last)
  end

  it 'should show with reply permission' do
    session[:user_id] = 2
    get :show, params: { board_id: 1, id: 1 }
    assert_response :success
    assert_template 'show'
    assert_select 'div',
                  attributes: { id: 'reply' },
                  descendant: { tag: 'textarea', attributes: { id: 'reply_content' } }
  end

  it 'should show message not found' do
    get :show, params: { board_id: 1, id: 99999 }
    assert_response 404
  end

  it 'should get new' do
    session[:user_id] = 2
    get :new, params: { board_id: 1 }
    assert_response :success
    assert_template 'new'
  end

  it 'should post create' do
    session[:user_id] = 2
    allow(Setting).to receive(:notified_events).and_return ['message_posted']

    post :create,
         params: {
           board_id: 1,
           message: {
             subject: 'Test created message',
             content: 'Message body'
           }
         }
    message = Message.find_by(subject: 'Test created message')
    refute_nil message
    assert_redirected_to topic_path(message)
    assert_equal 'Message body', message.content
    assert_equal 2, message.author_id
    assert_equal 1, message.board_id

    # author
    mails_to_author = ActionMailer::Base.deliveries.select { |m| m.to.include?('jsmith@somenet.foo') }
    assert_equal 1, mails_to_author.length
    mail = mails_to_author.first
    assert mail.to.include?('jsmith@somenet.foo')
    assert_kind_of Mail::Message, mail
    assert_equal "[#{message.board.project.name} - #{message.board.name} - msg#{message.root.id}] Test created message",
                 mail.subject
    assert mail.body.encoded.include?('Message body')

    # project member
    mails_to_member = ActionMailer::Base.deliveries.select { |m| m.to.include?('dlopper@somenet.foo') }
    assert_equal 1, mails_to_member.length
    assert mails_to_member.first.to.include?('dlopper@somenet.foo')
  end

  it 'should get edit' do
    session[:user_id] = 2
    get :edit, params: { id: 1 }
    assert_response :success
    assert_template 'edit'
  end

  it 'should put update' do
    session[:user_id] = 2
    put :update,
        params: {
          id: 1,
          message: {
            subject: 'New subject',
            content: 'New body'
          }
        }
    message = Message.find(1)
    assert_redirected_to topic_path(message)
    assert_equal 'New subject', message.subject
    assert_equal 'New body', message.content
  end

  it 'should reply' do
    session[:user_id] = 2
    post :reply, params: { board_id: 1, id: 1, reply: { content: 'This is a test reply', subject: 'Test reply' } }
    reply = Message.order('id DESC').first
    assert_redirected_to topic_path(1, r: reply)
    assert Message.find_by(subject: 'Test reply')
  end

  it 'should destroy topic' do
    session[:user_id] = 2
    delete :destroy, params: { id: 1 }
    assert_redirected_to project_board_path('ecookbook', 1)
    assert_nil Message.find_by(id: 1)
  end

  it 'should quote' do
    session[:user_id] = 2
    get :quote, params: { board_id: 1, id: 3 }, xhr: true
    assert_response :success
    assert_template 'quote'
  end
end

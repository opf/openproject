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
require 'legacy_spec_helper'

describe Message, type: :model do
  fixtures :all

  before do
    Setting.notified_events = ['message_posted']
    @board = Board.find(1)
    @user = User.find(1)
  end

  it 'should create' do
    topics_count = @board.topics_count
    messages_count = @board.messages_count

    message = Message.new(board: @board, subject: 'Test message', content: 'Test message content', author: @user)
    assert message.save
    @board.reload
    # topics count incremented
    assert_equal topics_count + 1, @board[:topics_count]
    # messages count incremented
    assert_equal messages_count + 1, @board[:messages_count]
    assert_equal message, @board.last_message
    # author should be watching the message
    assert message.watched_by?(@user)
  end

  it 'should reply' do
    topics_count = @board.topics_count
    messages_count = @board.messages_count
    @message = Message.find(1)
    replies_count = @message.replies_count

    reply_author = User.find(2)
    reply = Message.new(board: @board, subject: 'Test reply', content: 'Test reply content', parent: @message, author: reply_author)
    assert reply.save
    @board.reload
    # same topics count
    assert_equal topics_count, @board[:topics_count]
    # messages count incremented
    assert_equal messages_count + 1, @board[:messages_count]
    assert_equal reply, @board.last_message
    @message.reload
    # replies count incremented
    assert_equal replies_count + 1, @message[:replies_count]
    assert_equal reply, @message.last_reply
    # author should be watching the message
    assert @message.watched_by?(reply_author)
  end

  it 'should moving message should update counters' do
    @message = Message.find(1)
    assert_no_difference 'Message.count' do
      # Previous board
      assert_difference 'Board.find(1).topics_count', -1 do
        assert_difference 'Board.find(1).messages_count', -(1 + @message.replies_count) do
          # New board
          assert_difference 'Board.find(2).topics_count' do
            assert_difference 'Board.find(2).messages_count', (1 + @message.replies_count) do
              @message.update_attributes(board_id: 2)
            end
          end
        end
      end
    end
  end

  it 'should destroy topic' do
    message = Message.find(1)
    board = message.board
    topics_count = board.topics_count
    messages_count = board.messages_count

    assert_difference('Watcher.count', -1) do
      assert message.destroy
    end
    board.reload

    # Replies deleted
    assert Message.where(parent_id: 1).empty?
    # Checks counters
    assert_equal topics_count - 1, board.topics_count
    assert_equal messages_count - 3, board.messages_count
    # Watchers removed
  end

  it 'should destroy reply' do
    message = Message.find(5)
    board = message.board
    topics_count = board.topics_count
    messages_count = board.messages_count
    assert message.destroy
    board.reload

    # Checks counters
    assert_equal topics_count, board.topics_count
    assert_equal messages_count - 1, board.messages_count
  end

  it 'should editable by' do
    message = Message.find(6)
    author = message.author
    assert message.editable_by?(author)

    author.roles_for_project(message.project).first.remove_permission!(:edit_own_messages)
    assert !message.reload.editable_by?(author.reload)
  end

  it 'should destroyable by' do
    message = Message.find(6)
    author = message.author
    assert message.destroyable_by?(author)

    author.roles_for_project(message.project).first.remove_permission!(:delete_own_messages)
    assert !message.reload.destroyable_by?(author.reload)
  end

  it 'should set sticky' do
    message = Message.new
    assert_equal 0, message.sticky
    message.sticky = nil
    assert_equal 0, message.sticky
    message.sticky = false
    assert_equal 0, message.sticky
    message.sticky = true
    assert_equal 1, message.sticky
    message.sticky = '0'
    assert_equal 0, message.sticky
    message.sticky = '1'
    assert_equal 1, message.sticky
  end

  specify 'email notifications for creating a message' do
    assert_difference('ActionMailer::Base.deliveries.count', 3) do
      message = Message.new(board: @board, subject: 'Test message', content: 'Test message content', author: @user)
      assert message.save
    end
  end
end

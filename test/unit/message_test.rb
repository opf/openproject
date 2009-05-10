# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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

class MessageTest < Test::Unit::TestCase
  fixtures :projects, :roles, :members, :member_roles, :boards, :messages, :users, :watchers

  def setup
    @board = Board.find(1)
    @user = User.find(1)
  end
  
  def test_create
    topics_count = @board.topics_count
    messages_count = @board.messages_count
    
    message = Message.new(:board => @board, :subject => 'Test message', :content => 'Test message content', :author => @user)
    assert message.save
    @board.reload
    # topics count incremented
    assert_equal topics_count+1, @board[:topics_count]
    # messages count incremented
    assert_equal messages_count+1, @board[:messages_count]
    assert_equal message, @board.last_message
    # author should be watching the message
    assert message.watched_by?(@user)
  end
  
  def test_reply
    topics_count = @board.topics_count
    messages_count = @board.messages_count
    @message = Message.find(1)
    replies_count = @message.replies_count
    
    reply_author = User.find(2)
    reply = Message.new(:board => @board, :subject => 'Test reply', :content => 'Test reply content', :parent => @message, :author => reply_author)
    assert reply.save
    @board.reload
    # same topics count
    assert_equal topics_count, @board[:topics_count]
    # messages count incremented
    assert_equal messages_count+1, @board[:messages_count]
    assert_equal reply, @board.last_message
    @message.reload
    # replies count incremented
    assert_equal replies_count+1, @message[:replies_count]
    assert_equal reply, @message.last_reply
    # author should be watching the message
    assert @message.watched_by?(reply_author)
  end
  
  def test_moving_message_should_update_counters
    @message = Message.find(1)
    assert_no_difference 'Message.count' do
      # Previous board
      assert_difference 'Board.find(1).topics_count', -1 do
        assert_difference 'Board.find(1).messages_count', -(1 + @message.replies_count) do
          # New board
          assert_difference 'Board.find(2).topics_count' do
            assert_difference 'Board.find(2).messages_count', (1 + @message.replies_count) do
              @message.update_attributes(:board_id => 2)
            end
          end
        end
      end
    end
  end
  
  def test_destroy_topic
    message = Message.find(1)
    board = message.board
    topics_count, messages_count = board.topics_count, board.messages_count    
    
    assert_difference('Watcher.count', -1) do
      assert message.destroy
    end
    board.reload
    
    # Replies deleted
    assert Message.find_all_by_parent_id(1).empty?
    # Checks counters
    assert_equal topics_count - 1, board.topics_count
    assert_equal messages_count - 3, board.messages_count
    # Watchers removed
  end
  
  def test_destroy_reply
    message = Message.find(5)
    board = message.board
    topics_count, messages_count = board.topics_count, board.messages_count    
    assert message.destroy
    board.reload

    # Checks counters
    assert_equal topics_count, board.topics_count
    assert_equal messages_count - 1, board.messages_count
  end
  
  def test_editable_by
    message = Message.find(6)
    author = message.author
    assert message.editable_by?(author)
    
    author.roles_for_project(message.project).first.remove_permission!(:edit_own_messages)
    assert !message.reload.editable_by?(author.reload)
  end
  
  def test_destroyable_by
    message = Message.find(6)
    author = message.author
    assert message.destroyable_by?(author)
    
    author.roles_for_project(message.project).first.remove_permission!(:delete_own_messages)
    assert !message.reload.destroyable_by?(author.reload)
  end
end

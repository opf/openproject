require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  fixtures :projects, :boards, :messages, :users, :watchers

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
end

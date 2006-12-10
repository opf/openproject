require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  fixtures :users, :news, :comments

  def setup
    @jsmith = User.find(2)
    @news = News.find(1)
  end
  
  def test_create
    comment = Comment.new(:commented => @news, :author => @jsmith, :comment => "my comment")
    assert comment.save
    @news.reload
    assert_equal 2, @news.comments_count
  end

  def test_validate
    comment = Comment.new(:commented => @news)
    assert !comment.save
    assert_equal 2, comment.errors.length
  end
  
  def test_destroy
    comment = Comment.find(1)
    assert comment.destroy
    @news.reload
    assert_equal 0, @news.comments_count
  end
end

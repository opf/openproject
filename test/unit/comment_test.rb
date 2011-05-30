#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class CommentTest < ActiveSupport::TestCase
  fixtures :users, :news, :comments

  def setup
    @jsmith = User.find(2)
    @news = News.find(1)
  end

  def test_create
    comment = Comment.new(:commented => @news, :author => @jsmith, :comments => "my comment")
    assert comment.save
    @news.reload
    assert_equal 2, @news.comments_count
  end

  def test_create_should_send_notification
    Setting.notified_events = Setting.notified_events.dup << 'news_comment_added'
    Watcher.create!(:watchable => @news, :user => @jsmith)

    assert_difference 'ActionMailer::Base.deliveries.size' do
      Comment.create!(:commented => @news, :author => @jsmith, :comments => "my comment")
    end
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

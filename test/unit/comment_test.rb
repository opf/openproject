#-- encoding: UTF-8
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
require_relative '../test_helper'

class CommentTest < ActiveSupport::TestCase
  def setup
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def test_validations
    # factory valid
    assert FactoryGirl.build(:comment).valid?

    # comment text required
    refute FactoryGirl.build(:comment, :comments => '').valid?
    # object that is commented required
    refute FactoryGirl.build(:comment, :commented => nil).valid?
    # author required
    refute FactoryGirl.build(:comment, :author => nil).valid?
  end

  def test_create
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    comment = Comment.new(:commented => news, :author => user, :comments => 'some important words')
    assert comment.save
    assert_equal 1, news.reload.comments_count
  end

  def test_create_through_news
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    comment = news.new_comment(:author => user, :comments => 'some important words')
    assert comment.save
    assert_equal 1, news.reload.comments_count
  end

  def test_create_comment_through_news
    user = FactoryGirl.create(:user)
    news = FactoryGirl.create(:news)
    news.post_comment!(:author => user, :comments => 'some important words')
    assert_equal 1, news.reload.comments_count
  end

  def test_text
    comment = FactoryGirl.build(:comment, :comments => 'something useful')
    assert_equal 'something useful', comment.text
  end

  def test_create_should_send_notification_with_settings
    # news needs a project in order to be notified
    # see Redmine::Acts::Journalized::Deprecated#recipients
    project = FactoryGirl.create(:project)
    news = FactoryGirl.create(:news, :project => project)
    user = FactoryGirl.create(:user)

    # this makes #user to receive a notification
    Watcher.create!(:watchable => news, :user => user)

    # with notifications for that event turned on
    Notifier.stubs(:notify?).with(:news_comment_added).returns(true)
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      Comment.create!(:commented => news, :author => user, :comments => 'more useful stuff')
    end

    # with notifications for that event turned off
    Notifier.stubs(:notify?).with(:news_comment_added).returns(false)
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      Comment.create!(:commented => news, :author => user, :comments => 'more useful stuff')
    end
  end

  # TODO: testing #destroy really needed?
  def test_destroy
    # just setup
    news = FactoryGirl.create(:news)
    comment = FactoryGirl.build(:comment)
    news.comments << comment
    assert comment.persisted?

    # #reload is needed to refresh the count
    assert_equal 1, news.reload.comments_count
    comment.destroy
    assert_equal 0, news.reload.comments_count
  end
end

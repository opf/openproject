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
require File.expand_path('../../test_helper', __FILE__)

class WatcherTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    @user = User.find(1)
    @issue = Issue.find(1)
  end

  def test_watch
    assert @issue.add_watcher(@user)
    @issue.reload
    assert @issue.watchers.detect { |w| w.user == @user }
  end

  def test_cant_watch_twice
    assert @issue.add_watcher(@user)
    assert !@issue.add_watcher(@user)
  end

  def test_watched_by
    assert @issue.add_watcher(@user)
    @issue.reload
    assert @issue.watched_by?(@user)
    assert Issue.watched_by(@user).include?(@issue)
  end

  def test_watcher_users
    watcher_users = Issue.find(2).watcher_users
    assert_kind_of Array, watcher_users
    assert_kind_of User, watcher_users.first
  end

  def test_watcher_users_should_not_validate_user
    User.update_all("firstname = ''", "id=1")
    @user.reload
    assert !@user.valid?

    issue = Issue.new(:project => Project.find(1), :tracker_id => 1, :subject => "test", :author => User.find(2))
    issue.watcher_users << @user
    issue.save!
    assert issue.watched_by?(@user)
  end

  def test_watcher_user_ids
    assert_equal [1, 3], Issue.find(2).watcher_user_ids.sort
  end

  def test_watcher_user_ids=
    issue = Issue.new
    issue.watcher_user_ids = ['1', '3']
    assert issue.watched_by?(User.find(1))
  end

  def test_recipients
    @issue.watchers.delete_all
    @issue.reload

    assert @issue.watcher_recipients.empty?
    assert @issue.add_watcher(@user)

    @user.mail_notification = 'all'
    @user.save!
    @issue.reload
    assert @issue.watcher_recipients.include?(@user.mail)

    @user.mail_notification = 'none'
    @user.save!
    @issue.reload
    assert !@issue.watcher_recipients.include?(@user.mail)
  end

  def test_unwatch
    assert @issue.add_watcher(@user)
    @issue.reload
    assert_equal 1, @issue.remove_watcher(@user)
  end

  def test_prune
    Watcher.delete_all("user_id = 9")
    user = User.find(9)

    # public
    Watcher.create!(:watchable => Issue.find(1), :user => user)
    Watcher.create!(:watchable => Issue.find(2), :user => user)
    Watcher.create!(:watchable => Message.find(1), :user => user)
    Watcher.create!(:watchable => Wiki.find(1), :user => user)
    Watcher.create!(:watchable => WikiPage.find(2), :user => user)

    # private project (id: 2)
    Member.create!(:project => Project.find(2), :principal => user, :role_ids => [1])
    Watcher.create!(:watchable => Issue.find(4), :user => user)
    Watcher.create!(:watchable => Message.find(7), :user => user)
    Watcher.create!(:watchable => Wiki.find(2), :user => user)
    Watcher.create!(:watchable => WikiPage.find(3), :user => user)

    assert_no_difference 'Watcher.count' do
      Watcher.prune(:user => User.find(9))
    end

    Member.delete_all

    assert_difference 'Watcher.count', -4 do
      Watcher.prune(:user => User.find(9))
    end

    assert Issue.find(1).watched_by?(user)
    assert !Issue.find(4).watched_by?(user)
  end

  context "group watch" do
    setup do
      @group = Group.generate!
      Member.generate!(:project => Project.find(1), :roles => [Role.find(1)], :principal => @group)
      @group.users << @user = User.find(1)
      @group.users << @user2 = User.find(2)
    end
    
    should "be valid" do
      assert @issue.add_watcher(@group)
      @issue.reload
      assert @issue.watchers.detect { |w| w.user == @group }
    end
    
    should "add all group members to recipients" do
      @issue.watchers.delete_all
      @issue.reload
    
      assert @issue.watcher_recipients.empty?
      assert @issue.add_watcher(@group)

      @user.save    
      @issue.reload
      assert @issue.watcher_recipients.include?(@user.mail)
      assert @issue.watcher_recipients.include?(@user2.mail)

    end
    
  end
end

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

require File.expand_path('../../test_helper', __FILE__)

class WatcherTest < ActiveSupport::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules,
           :issues,
           :boards, :messages,
           :wikis, :wiki_pages,
           :watchers

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
  
  def test_watcher_user_ids
    issue = Issue.new
    issue.watcher_user_ids = ['1', '3']
    assert issue.watched_by?(User.find(1))
  end
  
  def test_recipients
    @issue.watchers.delete_all
    @issue.reload
    
    assert @issue.watcher_recipients.empty?
    assert @issue.add_watcher(@user)

    @user.mail_notification = true
    @user.save    
    @issue.reload
    assert @issue.watcher_recipients.include?(@user.mail)

    @user.mail_notification = false
    @user.save    
    @issue.reload
    assert @issue.watcher_recipients.include?(@user.mail)
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
end

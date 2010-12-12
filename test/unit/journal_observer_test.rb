# redMine - project management software
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

class JournalObserverTest < ActiveSupport::TestCase
  fixtures :issues, :issue_statuses, :journals, :journal_details

  def setup
    ActionMailer::Base.deliveries.clear
    @journal = Journal.find 1
  end

  # context: issue_updated notified_events
  def test_create_should_send_email_notification_with_issue_updated
    Setting.notified_events = ['issue_updated']
    issue = Issue.find(:first)
    user = User.find(:first)
    journal = issue.init_journal(user, issue)

    assert journal.save
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_create_should_not_send_email_notification_without_issue_updated
    Setting.notified_events = []
    issue = Issue.find(:first)
    user = User.find(:first)
    journal = issue.init_journal(user, issue)

    assert journal.save
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  # context: issue_note_added notified_events
  def test_create_should_send_email_notification_with_issue_note_added
    Setting.notified_events = ['issue_note_added']
    issue = Issue.find(:first)
    user = User.find(:first)
    journal = issue.init_journal(user, issue)
    journal.notes = 'This update has a note'

    assert journal.save
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_create_should_not_send_email_notification_without_issue_note_added
    Setting.notified_events = []
    issue = Issue.find(:first)
    user = User.find(:first)
    journal = issue.init_journal(user, issue)
    journal.notes = 'This update has a note'
    
    assert journal.save
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  # context: issue_status_updated notified_events
  def test_create_should_send_email_notification_with_issue_status_updated
    Setting.notified_events = ['issue_status_updated']
    issue = Issue.find(:first)
    user = User.find(:first)
    issue.init_journal(user, issue)
    issue.status = IssueStatus.last

    assert issue.save
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_create_should_not_send_email_notification_without_issue_status_updated
    Setting.notified_events = []
    issue = Issue.find(:first)
    user = User.find(:first)
    issue.init_journal(user, issue)
    issue.status = IssueStatus.last
    
    assert issue.save
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  # context: issue_priority_updated notified_events
  def test_create_should_send_email_notification_with_issue_priority_updated
    Setting.notified_events = ['issue_priority_updated']
    issue = Issue.find(:first)
    user = User.find(:first)
    issue.init_journal(user, issue)
    issue.priority = IssuePriority.last

    assert issue.save
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_create_should_not_send_email_notification_without_issue_priority_updated
    Setting.notified_events = []
    issue = Issue.find(:first)
    user = User.find(:first)
    issue.init_journal(user, issue)
    issue.priority = IssuePriority.last
    
    assert issue.save
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

end

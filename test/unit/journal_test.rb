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

class JournalTest < ActiveSupport::TestCase
  fixtures :issues, :issue_statuses, :journals

  def setup
    @journal = IssueJournal.find(1)
  end

  def test_journalized_is_an_issue
    issue = @journal.journalized
    assert_kind_of Issue, issue
    assert_equal 1, issue.id
  end

  def test_new_status
    status = @journal.new_status
    assert_not_nil status
    assert_kind_of IssueStatus, status
    assert_equal 2, status.id 
  end
  
  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(:first)
    if issue.journals.empty?
      issue.init_journal(User.current, "This journal represents the creational journal version 1")
      issue.save
    end
    user = User.find(:first)

    assert_equal 0, ActionMailer::Base.deliveries.size
    issue.update_attribute(:subject, "New subject to trigger automatic journal entry")
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
  
  def test_create_should_not_send_email_notification_if_told_not_to
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(:first)
    user = User.find(:first)
    journal = issue.init_journal(user, "A note")
    JournalObserver.instance.send_notification = false

    assert_difference("Journal.count") do
      assert issue.save
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
  end
end

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

class JournalObserverTest < ActiveSupport::TestCase
  def setup
    @user = User.generate!(:mail_notification => 'all')
    @project = Project.generate!
    User.add_to_project(@user, @project, Role.generate!(:permissions => [:view_issues, :edit_issues]))
    @issue = Issue.generate_for_project!(@project)
    ActionMailer::Base.deliveries.clear
  end

  context "#after_create for 'issue_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_updated']
      assert_difference('ActionMailer::Base.deliveries.size', 2) do
        @issue.init_journal(@user)
        @issue.subject = "A change to the issue"
        assert @issue.save
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.init_journal(@user)
        @issue.subject = "A change to the issue"
        assert @issue.save
      end
    end

  end

  context "#after_create for 'issue_note_added'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_note_added']
      assert_difference('ActionMailer::Base.deliveries.size', 2) do
        @issue.init_journal(@user, 'This update has a note')
        assert @issue.save
      end

    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.init_journal(@user, 'This update has a note')
        assert @issue.save
      end

    end
  end

  context "#after_create for 'issue_status_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_status_updated']
      assert_difference('ActionMailer::Base.deliveries.size', 2) do
        @issue.init_journal(@user)
        @issue.status = IssueStatus.generate!
        assert @issue.save

      end

    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.init_journal(@user)
        @issue.status = IssueStatus.generate!
        assert @issue.save

      end
    end
  end

  context "#after_create for 'issue_priority_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_priority_updated']
      assert_difference('ActionMailer::Base.deliveries.size', 2) do
        @issue.init_journal(@user)
        @issue.priority = IssuePriority.generate!
        assert @issue.save
      end

    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.init_journal(@user)
        @issue.priority = IssuePriority.generate!
        assert @issue.save
      end

    end
  end
end

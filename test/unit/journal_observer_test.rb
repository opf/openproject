#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class JournalObserverTest < ActiveSupport::TestCase
  def setup
    super
    @project = FactoryGirl.create :valid_project
    @user = FactoryGirl.create :user, :mail_notification => 'all', :member_in_project => @project
    @issue = FactoryGirl.create :issue, :project => @project, :author => @user, :type => @project.types.first
    ActionMailer::Base.deliveries.clear
  end

  context "#after_create for 'issue_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_updated']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user)
        @issue.subject = "A change to the issue"
        assert @issue.save
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user)
        @issue.subject = "A change to the issue"
        assert @issue.save
      end
    end
  end

  context "#after_create for 'issue_note_added'" do
    should "should send a notification when configured as a notification" do
      @issue.recreate_initial_journal!

      Setting.notified_events = ['issue_note_added']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user, 'This update has a note')
        assert @issue.save
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user, 'This update has a note')
        assert @issue.save
      end
    end
  end

  context "#after_create for 'issue_status_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_status_updated']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user)
        @issue.status = IssueStatus.generate!
        assert @issue.save
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user)
        @issue.status = IssueStatus.generate!
        assert @issue.save
      end
    end
  end

  context "#after_create for 'issue_priority_updated'" do
    should "should send a notification when configured as a notification" do
      Setting.notified_events = ['issue_priority_updated']
      assert_difference('ActionMailer::Base.deliveries.size', +1) do
        @issue.add_journal(@user)
        @issue.priority = IssuePriority.generate!
        assert @issue.save
      end
    end

    should "not send a notification with not configured" do
      Setting.notified_events = []
      assert_no_difference('ActionMailer::Base.deliveries.size') do
        @issue.add_journal(@user)
        @issue.priority = IssuePriority.generate!
        assert @issue.save
      end
    end
  end
end

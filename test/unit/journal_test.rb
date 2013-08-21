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

class JournalTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    super
  end

  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(:first)
    if issue.journals.empty?
      issue.add_journal(User.current, "This journal represents the creationa of journal version 1")
      issue.save
    end
    user = User.find(:first)
    assert_equal 0, ActionMailer::Base.deliveries.size
    issue.reload
    issue.update_attribute(:subject, "New subject to trigger automatic journal entry")
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_create_should_not_send_email_notification_if_told_not_to
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(:first)
    user = User.find(:first)
    journal = issue.add_journal(user, "A note")
    JournalObserver.instance.send_notification = false

    assert_difference("Journal.count") do
      assert issue.save
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "creating the initial journal should track the changes from creation" do
    Journal.delete_all
    @project = Project.generate!
    issue = Issue.new do |i|
      i.project = @project
      i.subject = "Test initial journal"
      i.type = @project.types.first
      i.author = User.generate!
      i.description = "Some content"
    end

    assert_difference("Journal.count") do
      assert issue.save
    end

    journal = issue.reload.journals.first
    assert_equal [nil,"Test initial journal"], journal.changed_data[:subject]
    assert_equal [nil, @project.id], journal.changed_data[:project_id]
    assert_equal [nil, "Some content"], journal.changed_data[:description]
  end

  test "creating a journal should update the updated_on value of the parent record (touch)" do
    @user = User.generate!
    @project = Project.generate!
    @issue = Issue.generate_for_project!(@project).reload
    start = @issue.updated_at
    sleep(1) # TODO: massive hack to make sure the timestamps are different. switch to timecop later

    assert_difference("Journal.count") do
      @issue.add_journal(@user, "A note")
      @issue.save
    end

    assert_not_equal start, @issue.reload.updated_at
  end

  test "accessing #journaled on a Journal should not error (parent class)" do
    journal = Journal.new
    assert_nothing_raised do
      assert_equal nil, journal.journable
    end
  end

  test "setting journal fields through the journaled object for creation" do
    @issue = Issue.generate_for_project!(Project.generate!)

    @issue.add_journal @issue.author, 'Test setting fields on Journal from Issue'
    assert_difference('Journal.count') do
      assert @issue.save
    end

    assert_equal "Test setting fields on Journal from Issue", @issue.last_journal.notes
    assert_equal @issue.author, @issue.last_journal.user
  end
end

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

class IssueTest < ActiveSupport::TestCase
  include MiniTest::Assertions # refute

  fixtures :all

  context "Issue#recipients" do
    setup do
      @project = Project.find(1)
      @author = User.generate_with_protected!
      @assignee = User.generate_with_protected!
      @issue = Issue.generate_for_project!(@project, :assigned_to => @assignee, :author => @author)
    end

    should "include project recipients" do
      assert @project.recipients.present?
      @project.recipients.each do |project_recipient|
        assert @issue.recipients.include?(project_recipient)
      end
    end

    should "include the author if the author is active" do
      assert @issue.author, "No author set for Issue"
      assert @issue.recipients.include?(@issue.author.mail)
    end

    should "include the assigned to user if the assigned to user is active" do
      assert @issue.assigned_to, "No assigned_to set for Issue"
      assert @issue.recipients.include?(@issue.assigned_to.mail)
    end

    should "not include users who opt out of all email" do
      @author.update_attribute(:mail_notification, :none)

      assert !@issue.recipients.include?(@issue.author.mail)
    end

    should "not include the issue author if they are only notified of assigned issues" do
      @author.update_attribute(:mail_notification, :only_assigned)

      assert !@issue.recipients.include?(@issue.author.mail)
    end

    should "not include the assigned user if they are only notified of owned issues" do
      @assignee.update_attribute(:mail_notification, :only_owner)

      assert !@issue.recipients.include?(@issue.assigned_to.mail)
    end

  end

  def test_create_should_not_send_email_notification_if_told_not_to
    Journal.delete_all
    ActionMailer::Base.deliveries.clear
    issue = Issue.new.tap do |i|
      i.force_attributes = { :project_id => 1,
                             :type_id => 1,
                             :author_id => 3,
                             :status_id => 1,
                             :priority => IssuePriority.first,
                             :subject => 'test_create',
                             :estimated_hours => '1:30' }
    end
    IssueObserver.instance.send_notification = false

    assert issue.save
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test 'changing the line endings in a description will not be recorded as a Journal' do
    User.current = User.find(1)
    issue = Issue.find(1)
    issue.update_attribute(:description, "Description with newlines\n\nembedded")
    issue.reload
    assert issue.description.include?("\n")

    assert_no_difference("Journal.count") do
      issue.safe_attributes= {
        'description' => "Description with newlines\r\n\r\nembedded"
      }
      assert issue.save
    end

    assert_equal "Description with newlines\n\nembedded", issue.reload.description
  end

end

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

  context "#behind_schedule?" do
    should "be false if the issue has no start_date" do
      assert !Issue.new(:start_date => nil, :due_date => 1.day.from_now.to_date, :done_ratio => 0).behind_schedule?
    end

    should "be false if the issue has no due_date" do
      assert !Issue.new(:start_date => 1.day.from_now.to_date, :due_date => nil, :done_ratio => 0).behind_schedule?
    end

    should "be false if the issue has more done than it's calendar time" do
      assert !Issue.new(:start_date => 50.days.ago.to_date, :due_date => 50.days.from_now.to_date, :done_ratio => 90).behind_schedule?
    end

    should "be true if the issue hasn't been started at all" do
      assert Issue.new(:start_date => 1.day.ago.to_date, :due_date => 1.day.from_now.to_date, :done_ratio => 0).behind_schedule?
    end

    should "be true if the issue has used more calendar time than it's done ratio" do
      assert Issue.new(:start_date => 100.days.ago.to_date, :due_date => Date.today, :done_ratio => 90).behind_schedule?
    end
  end

  context "#assignable_users" do
    should "be Users" do
      assert_kind_of User, Issue.find(1).assignable_users.first
    end

    should "not show the issue author twice" do
      assignable_user_ids = Issue.find(1).assignable_users.collect(&:id)
      assert_equal 2, assignable_user_ids.length

      assignable_user_ids.each do |user_id|
        assert_equal 1, assignable_user_ids.select {|i| i == user_id}.length, "User #{user_id} appears more or less than once"
      end
    end
  end

  def test_create_should_send_email_notification
    Journal.delete_all
    ActionMailer::Base.deliveries.clear
    issue = Issue.new.tap do |i|
      i.force_attributes = { :project_id => 1,
                             :type_id => 1,
                             :author_id => 3,
                             :status_id => 1,
                             :priority => IssuePriority.all.first,
                             :subject => 'test_create',
                             :estimated_hours => '1:30' }
    end

    assert issue.save
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_stale_issue_should_not_send_email_notification
    Journal.delete_all
    ActionMailer::Base.deliveries.clear
    i = FactoryGirl.create :issue
    i.add_journal(User.find(1))

    issue = Issue.find(i.id)
    stale = Issue.find(i.id)

    issue.subject = 'Subjet update'
    assert issue.save
    assert_equal 2, ActionMailer::Base.deliveries.size
    ActionMailer::Base.deliveries.clear

    stale.add_journal(User.find(1))
    stale.subject = 'Another subjet update'
    assert_raise ActiveRecord::StaleObjectError do
      stale.save
    end
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_journalized_description
    WorkPackageCustomField.delete_all

    i = Issue.first
    i.recreate_initial_journal!
    i.reload
    old_description = i.description
    new_description = "This is the new description"

    i.add_journal(User.find(2))
    i.description = new_description
    assert_difference 'Journal.count', 1 do
      i.save!
    end

    journal = Journal.first(:order => 'id DESC')
    assert_equal i, journal.journable
    assert journal.changed_data.has_key? :description
    assert_equal old_description, journal.old_value_for("description")
    assert_equal new_description, journal.new_value_for("description")
  end

  def test_all_dependent_issues
    IssueRelation.delete_all
    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(1),
                             :issue_to => Issue.find(2),
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end
    assert relation.save

    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(2),
                             :issue_to => Issue.find(3),
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end
    assert relation.save

    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(3),
                             :issue_to => Issue.find(8),
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end
    assert relation.save

    assert_equal [2, 3, 8], Issue.find(1).all_dependent_issues.collect(&:id).sort
  end

  def test_all_dependent_issues_with_persistent_circular_dependency
    IssueRelation.delete_all
    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(1),
                             :issue_to => Issue.find(2),
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end
    assert relation.save
    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(2),
                             :issue_to => Issue.find(3),
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end
    assert relation.save
    # Validation skipping
    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(3),
                             :issue_to => Issue.find(1),
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end
    assert relation.save(:validate => false)

    assert_equal [2, 3], Issue.find(1).all_dependent_issues.collect(&:id).sort
  end

  def test_all_dependent_issues_with_persistent_multiple_circular_dependencies
    IssueRelation.delete_all
    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(1),
                             :issue_to => Issue.find(2),
                             :relation_type => IssueRelation::TYPE_RELATES }
    end
    assert relation.save

    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(2),
                             :issue_to => Issue.find(3),
                             :relation_type => IssueRelation::TYPE_RELATES }
    end
    assert relation.save

    relation = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => Issue.find(3),
                             :issue_to => Issue.find(8),
                             :relation_type => IssueRelation::TYPE_RELATES }
    end
    assert relation.save

    # Validation skipping
    relation = IssueRelation.new.tap do |i|
      i. force_attributes = { :issue_from => Issue.find(8),
                              :issue_to => Issue.find(2),
                              :relation_type => IssueRelation::TYPE_RELATES }
    end
    assert relation.save(:validate => false)

    relation = IssueRelation.new.tap do |i|
      i. force_attributes = { :issue_from => Issue.find(3),
                              :issue_to => Issue.find(1),
                              :relation_type => IssueRelation::TYPE_RELATES }
    end
    assert relation.save(:validate => false)

    assert_equal [2, 3, 8], Issue.find(1).all_dependent_issues.collect(&:id).sort
  end

  context "#done_ratio" do
    setup do
      @issue = Issue.find(1)
      @issue_status = IssueStatus.find(1)
      @issue_status.update_attribute(:default_done_ratio, 50)
      @issue2 = Issue.find(2)
      @issue_status2 = IssueStatus.find(2)
      @issue_status2.update_attribute(:default_done_ratio, 0)
    end

    context "with Setting.issue_done_ratio using the issue_field" do
      setup do
        Setting.issue_done_ratio = 'issue_field'
      end

      should "read the issue's field" do
        assert_equal 0, @issue.done_ratio
        assert_equal 30, @issue2.done_ratio
      end
    end

    context "with Setting.issue_done_ratio using the issue_status" do
      setup do
        Setting.issue_done_ratio = 'issue_status'
      end

      should "read the Issue Status's default done ratio" do
        assert_equal 50, @issue.done_ratio
        assert_equal 0, @issue2.done_ratio
      end
    end
  end

  context "#update_done_ratio_from_issue_status" do
    setup do
      @issue = Issue.find(1)
      @issue_status = IssueStatus.find(1)
      @issue_status.update_attribute(:default_done_ratio, 50)
      @issue2 = Issue.find(2)
      @issue_status2 = IssueStatus.find(2)
      @issue_status2.update_attribute(:default_done_ratio, 0)
    end

    context "with Setting.issue_done_ratio using the issue_field" do
      setup do
        Setting.issue_done_ratio = 'issue_field'
      end

      should "not change the issue" do
        @issue.update_done_ratio_from_issue_status
        @issue2.update_done_ratio_from_issue_status

        assert_equal 0, @issue.read_attribute(:done_ratio)
        assert_equal 30, @issue2.read_attribute(:done_ratio)
      end
    end

    context "with Setting.issue_done_ratio using the issue_status" do
      setup do
        Setting.issue_done_ratio = 'issue_status'
      end

      should "change the issue's done ratio" do
        @issue.update_done_ratio_from_issue_status
        @issue2.update_done_ratio_from_issue_status

        assert_equal 50, @issue.read_attribute(:done_ratio)
        assert_equal 0, @issue2.read_attribute(:done_ratio)
      end
    end
  end

  test "#by_type" do
    groups = Issue.by_type(Project.find(1))
    assert_equal 3, groups.size
    assert_equal 7, groups.inject(0) {|sum, group| sum + group['total'].to_i}
  end

  test "#by_version" do
    groups = Issue.by_version(Project.find(1))
    assert_equal 3, groups.size
    assert_equal 3, groups.inject(0) {|sum, group| sum + group['total'].to_i}
  end

  test "#by_priority" do
    groups = Issue.by_priority(Project.find(1))
    assert_equal 4, groups.size
    assert_equal 7, groups.inject(0) {|sum, group| sum + group['total'].to_i}
  end

  test "#by_category" do
    groups = Issue.by_category(Project.find(1))
    assert_equal 2, groups.size
    assert_equal 3, groups.inject(0) {|sum, group| sum + group['total'].to_i}
  end

  test "#by_assigned_to" do
    groups = Issue.by_assigned_to(Project.find(1))
    assert_equal 2, groups.size
    assert_equal 2, groups.inject(0) {|sum, group| sum + group['total'].to_i}
  end

  test "#by_author" do
    groups = Issue.by_author(Project.find(1))
    assert_equal 4, groups.size
    assert_equal 7, groups.inject(0) {|sum, group| sum + group['total'].to_i}
  end

  test "#by_subproject" do
    groups = Issue.by_subproject(Project.find(1))
    assert_equal 2, groups.size
    assert_equal 5, groups.inject(0) {|sum, group| sum + group['total'].to_i}
  end

  def test_recently_updated_with_limit_scopes
    #should return the last updated issue
    assert_equal 1, Issue.recently_updated.with_limit(1).length
    assert_equal Issue.find(:first, :order => "updated_at DESC"), Issue.recently_updated.with_limit(1).first
  end

  def test_on_active_projects_scope
    assert Project.find(2).archive

    before = Issue.on_active_project.length
    # test inclusion to results
    issue = Issue.generate_for_project!(Project.find(1), :type => Project.find(2).types.first)
    assert_equal before + 1, Issue.on_active_project.length

    # Move to an archived project
    issue.project = Project.find(2)
    assert issue.save
    assert_equal before, Issue.on_active_project.length
  end

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

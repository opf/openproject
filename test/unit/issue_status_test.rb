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

class IssueStatusTest < ActiveSupport::TestCase
  fixtures :issue_statuses, :issues, :roles, :trackers

  def test_create
    status = IssueStatus.new :name => "Assigned"
    assert !status.save
    # status name uniqueness
    assert_equal 1, status.errors.count
    
    status.name = "Test Status"
    assert status.save
    assert !status.is_default
  end
  
  def test_destroy
    status = IssueStatus.find(3)
    assert_difference 'IssueStatus.count', -1 do
      assert status.destroy
    end
    assert_nil Workflow.first(:conditions => {:old_status_id => status.id})
    assert_nil Workflow.first(:conditions => {:new_status_id => status.id})
  end

  def test_destroy_status_in_use
    # Status assigned to an Issue
    status = Issue.find(1).status
    assert_raise(RuntimeError, "Can't delete status") { status.destroy }
  end

  def test_default
    status = IssueStatus.default
    assert_kind_of IssueStatus, status
  end
  
  def test_change_default
    status = IssueStatus.find(2)
    assert !status.is_default
    status.is_default = true
    assert status.save
    status.reload
    
    assert_equal status, IssueStatus.default
    assert !IssueStatus.find(1).is_default
  end
  
  def test_reorder_should_not_clear_default_status
    status = IssueStatus.default
    status.move_to_bottom
    status.reload
    assert status.is_default?
  end
  
  def test_new_statuses_allowed_to
    Workflow.delete_all
    
    Workflow.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 1, :new_status_id => 2, :author => false, :assignee => false)
    Workflow.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 1, :new_status_id => 3, :author => true, :assignee => false)
    Workflow.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 1, :new_status_id => 4, :author => false, :assignee => true)
    Workflow.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 1, :new_status_id => 5, :author => true, :assignee => true)
    status = IssueStatus.find(1)
    role = Role.find(1)
    tracker = Tracker.find(1)

    assert_equal [2], status.new_statuses_allowed_to([role], tracker, false, false).map(&:id)
    assert_equal [2], status.find_new_statuses_allowed_to([role], tracker, false, false).map(&:id)
    
    assert_equal [2, 3], status.new_statuses_allowed_to([role], tracker, true, false).map(&:id)
    assert_equal [2, 3], status.find_new_statuses_allowed_to([role], tracker, true, false).map(&:id)
    
    assert_equal [2, 4], status.new_statuses_allowed_to([role], tracker, false, true).map(&:id)
    assert_equal [2, 4], status.find_new_statuses_allowed_to([role], tracker, false, true).map(&:id)
    
    assert_equal [2, 3, 4, 5], status.new_statuses_allowed_to([role], tracker, true, true).map(&:id)
    assert_equal [2, 3, 4, 5], status.find_new_statuses_allowed_to([role], tracker, true, true).map(&:id)
  end

  context "#update_done_ratios" do
    setup do
      @issue = Issue.find(1)
      @issue_status = IssueStatus.find(1)
      @issue_status.update_attribute(:default_done_ratio, 50)
    end
    
    context "with Setting.issue_done_ratio using the issue_field" do
      setup do
        Setting.issue_done_ratio = 'issue_field'
      end
      
      should "change nothing" do
        IssueStatus.update_issue_done_ratios

        assert_equal 0, Issue.count(:conditions => {:done_ratio => 50})
      end
    end

    context "with Setting.issue_done_ratio using the issue_status" do
      setup do
        Setting.issue_done_ratio = 'issue_status'
      end
      
      should "update all of the issue's done_ratios to match their Issue Status" do
        IssueStatus.update_issue_done_ratios
        
        issues = Issue.find([1,3,4,5,6,7,9,10])
        issues.each do |issue|
          assert_equal @issue_status, issue.status
          assert_equal 50, issue.read_attribute(:done_ratio)
        end
      end
    end
  end
end

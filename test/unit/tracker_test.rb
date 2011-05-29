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

class TrackerTest < ActiveSupport::TestCase
  fixtures :trackers, :workflows, :issue_statuses, :roles

  def test_copy_workflows
    source = Tracker.find(1)
    assert_equal 89, source.workflows.size
    
    target = Tracker.new(:name => 'Target')
    assert target.save
    target.workflows.copy(source)
    target.reload
    assert_equal 89, target.workflows.size
  end
  
  def test_issue_statuses
    tracker = Tracker.find(1)
    Workflow.delete_all
    Workflow.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 2, :new_status_id => 3)
    Workflow.create!(:role_id => 2, :tracker_id => 1, :old_status_id => 3, :new_status_id => 5)
    
    assert_kind_of Array, tracker.issue_statuses
    assert_kind_of IssueStatus, tracker.issue_statuses.first
    assert_equal [2, 3, 5], Tracker.find(1).issue_statuses.collect(&:id)
  end
  
  def test_issue_statuses_empty
    Workflow.delete_all("tracker_id = 1")
    assert_equal [], Tracker.find(1).issue_statuses
  end
end

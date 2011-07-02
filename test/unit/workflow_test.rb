#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

class WorkflowTest < ActiveSupport::TestCase
  fixtures :roles, :trackers, :issue_statuses

  def test_copy
    Workflow.delete_all
    Workflow.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 1, :new_status_id => 2)
    Workflow.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 1, :new_status_id => 3, :assignee => true)
    Workflow.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 1, :new_status_id => 4, :author => true)

    assert_difference 'Workflow.count', 3 do
      Workflow.copy(Tracker.find(2), Role.find(1), Tracker.find(3), Role.find(2))
    end

    assert_equal 1, Workflow.count(:conditions => {:role_id => 2, :tracker_id => 3, :old_status_id => 1, :new_status_id => 2, :author => false, :assignee => false})
    assert_equal 1, Workflow.count(:conditions => {:role_id => 2, :tracker_id => 3, :old_status_id => 1, :new_status_id => 3, :author => false, :assignee => true})
    assert_equal 1, Workflow.count(:conditions => {:role_id => 2, :tracker_id => 3, :old_status_id => 1, :new_status_id => 4, :author => true, :assignee => false})
  end
end

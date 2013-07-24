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

class TypeTest < ActiveSupport::TestCase
  fixtures :all

  def test_copy_workflows
    source = Type.find(1)
    assert_equal 89, source.workflows.size

    target = Type.new(:name => 'Target')
    assert target.save
    target.workflows.copy(source)
    target.reload
    assert_equal 89, target.workflows.size
  end

  def test_issue_statuses
    type = Type.find(1)
    Workflow.delete_all
    Workflow.create!(:role_id => 1, :type_id => 1, :old_status_id => 2, :new_status_id => 3)
    Workflow.create!(:role_id => 2, :type_id => 1, :old_status_id => 3, :new_status_id => 5)

    assert_kind_of Array, type.issue_statuses
    assert_kind_of IssueStatus, type.issue_statuses.first
    assert_equal [2, 3, 5], Type.find(1).issue_statuses.collect(&:id)
  end

  def test_issue_statuses_empty
    Workflow.delete_all("type_id = 1")
    assert_equal [], Type.find(1).issue_statuses
  end
end

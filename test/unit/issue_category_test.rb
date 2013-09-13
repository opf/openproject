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

class IssueCategoryTest < ActiveSupport::TestCase
  def setup
    super
    @project = FactoryGirl.create :project
    @category = FactoryGirl.create :issue_category, :project => @project
    @issue = FactoryGirl.create :work_package, :category => @category
    assert_equal @issue.category, @category
    assert_equal @category.work_packages, [@issue]
  end

  def test_create
    assert IssueCategory.new(:project_id => 2, :name => 'New category').save
    category = IssueCategory.first(:order => 'id DESC')
    assert_equal 'New category', category.name
  end

  def test_create_with_group_assignment
    assert IssueCategory.new(:project_id => 2, :name => 'Group assignment', :assigned_to_id => 11).save
    category = IssueCategory.first(:order => 'id DESC')
    assert_kind_of Group, category.assigned_to
    assert_equal Group.find(11), category.assigned_to
  end

  # Make sure the category was nullified on the issue
  def test_destroy
    @category.destroy
    assert_nil @issue.reload.category
  end

  # both issue categories must be in the same project
  def test_destroy_with_reassign
    reassign_to = FactoryGirl.create :issue_category, :project => @project
    @category.destroy(reassign_to)
    # Make sure the issue was reassigned
    assert_equal reassign_to, @issue.reload.category
  end
end

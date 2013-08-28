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

class IssueNestedSetTest < ActiveSupport::TestCase
  include MiniTest::Assertions # refute

  fixtures :all

  self.use_transactional_fixtures = false

  def setup
    super
    Issue.delete_all
  end

  def test_creating_a_child_in_different_project_should_not_validate_unless_allowed
    Setting.cross_project_issue_relations = "0"
    issue = create_issue!
    child = Issue.new.tap do |i|
      i.force_attributes = { :project_id => 2,
                             :type_id => 1,
                             :author_id => 1,
                             :subject => 'child',
                             :parent_id => issue.id }
    end
    assert !child.save
    refute_empty child.errors[:parent_id]
  end

  def test_creating_a_child_in_different_project_should_validate_if_allowed
    Setting.cross_project_issue_relations = "1"
    issue = create_issue!
    child = Issue.new.tap do |i|
      i.force_attributes = { :project_id => 2,
                             :type_id => 1,
                             :author_id => 1,
                             :subject => 'child',
                             :parent_id => issue.id }
    end
    assert child.save
    assert_empty child.errors[:parent_id]
  end


  def test_move_a_child_with_descendants_to_another_project
    Setting.cross_project_issue_relations = "0"

    parent1 = create_issue!
    child =   create_issue!(:parent_id => parent1.id)
    grandchild = create_issue!(:parent_id => child.id)

    assert child.reload.move_to_project(Project.find(2))
    child.reload
    grandchild.reload
    parent1.reload

    assert_equal [1, parent1.id, 1], [parent1.project_id, parent1.root_id, parent1.nested_set_span]
    assert_equal [2, child.id, 3], [child.project_id, child.root_id, child.nested_set_span]
    assert_equal [2, child.id, 1], [grandchild.project_id, grandchild.root_id, grandchild.nested_set_span]
  end

  def test_invalid_move_to_another_project
    parent1 = create_issue!
    child =   create_issue!(:parent_id => parent1.id)
    grandchild = create_issue!(:parent_id => child.id, :type_id => 2)
    Project.find(2).type_ids = [1]

    parent1.reload
    assert_equal [1, parent1.id, 5], [parent1.project_id, parent1.root_id, parent1.nested_set_span]

    # child can not be moved to Project 2 because its child is on a disabled type
    assert_equal false, Issue.find(child.id).move_to_project(Project.find(2))
    child.reload
    grandchild.reload
    parent1.reload

    # no change
    assert_equal [1, parent1.id, 5], [parent1.project_id, parent1.root_id, parent1.nested_set_span]
    assert_equal [1, parent1.id, 3], [child.project_id, child.root_id, child.nested_set_span]
    assert_equal [1, parent1.id, 1], [grandchild.project_id, grandchild.root_id, grandchild.nested_set_span]
  end

  def test_moving_an_issue_to_a_descendant_should_not_validate
    parent1 = create_issue!
    parent2 = create_issue!
    child =   create_issue!(:parent_id => parent1.id)
    grandchild = create_issue!(:parent_id => child.id)

    child.reload
    child.parent_id = grandchild.id
    assert !child.save
    refute_empty child.errors[:parent_id]
  end

  def test_moving_an_issue_should_keep_valid_relations_only
    issue1 = create_issue!
    issue2 = create_issue!
    issue3 = create_issue!(:parent_id => issue2.id)
    issue4 = create_issue!
    (r1 = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => issue1,
                             :issue_to => issue2,
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end).save!
    (r2 = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => issue1,
                             :issue_to => issue3,
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end).save!
    (r3 = IssueRelation.new.tap do |i|
      i.force_attributes = { :issue_from => issue2,
                             :issue_to => issue4,
                             :relation_type => IssueRelation::TYPE_PRECEDES }
    end).save!
    issue2.reload
    issue2.parent_id = issue1.id
    issue2.save!
    assert !IssueRelation.exists?(r1.id)
    assert !IssueRelation.exists?(r2.id)
    assert IssueRelation.exists?(r3.id)
  end

  def test_destroy_should_destroy_children
    issue1 = create_issue!
    issue2 = create_issue!
    issue3 = create_issue!(:parent_id => issue2.id)
    issue4 = create_issue!(:parent_id => issue1.id)

    issue3.add_journal(User.find(2))
    issue3.subject = 'child with journal'
    issue3.save!

    assert_difference 'Issue.count', -2 do
      assert_difference 'Journal.count', -3 do
        Issue.find(issue2.id).destroy
      end
    end

    issue1.reload
    issue4.reload
    assert !Issue.exists?(issue2.id)
    assert !Issue.exists?(issue3.id)
    assert_equal [issue1.id, 3], [issue1.root_id, issue1.nested_set_span]
    assert_equal [issue1.id, 1], [issue4.root_id, issue4.nested_set_span]
  end

  def test_destroy_parent_issue_updated_during_children_destroy
    parent = create_issue!
    create_issue!(:start_date => Date.today, :parent_id => parent.id)
    create_issue!(:start_date => 2.days.from_now, :parent_id => parent.id)

    assert_difference 'Issue.count', -3 do
      Issue.find(parent.id).destroy
    end
  end

  def test_destroy_child_issue_with_children
    root = create_issue!(:project_id => 1, :author_id => 2, :type_id => 1, :subject => 'root').reload
    child = create_issue!(:project_id => 1, :author_id => 2, :type_id => 1, :subject => 'child', :parent_id => root.id).reload
    leaf = create_issue!(:project_id => 1, :author_id => 2, :type_id => 1, :subject => 'leaf', :parent_id => child.id).reload
    leaf.add_journal(User.find(2))
    leaf.subject = 'leaf with journal'
    leaf.save!

    total_journals_on_children = leaf.reload.journals.count + child.reload.journals.count
    assert_difference 'Issue.count', -2 do
      assert_difference 'Journal.count', -total_journals_on_children do
        Issue.find(child.id).destroy
      end
    end

    root = Issue.find(root.id)
    assert root.leaf?, "Root issue is not a leaf (lft: #{root.lft}, rgt: #{root.rgt})"
  end

  def test_destroy_issue_with_grand_child
    parent = create_issue!
    issue = create_issue!(:parent_id => parent.id)
    child = create_issue!(:parent_id => issue.id)
    grandchild1 = create_issue!(:parent_id => child.id)
    grandchild2 = create_issue!(:parent_id => child.id)

    assert_difference 'Issue.count', -4 do
      Issue.find(issue.id).destroy
      parent.reload
      assert_equal [1, 2], [parent.lft, parent.rgt], 'parent should not have children'
    end
  end

  def test_parent_priority_should_be_the_highest_child_priority
    parent = create_issue!(:priority => IssuePriority.find_by_name('Normal'))
    # Create children
    child1 = create_issue!(:priority => IssuePriority.find_by_name('High'), :parent_id => parent.id)
    assert_equal 'High', parent.reload.priority.name
    child2 = create_issue!(:priority => IssuePriority.find_by_name('Immediate'), :parent_id => child1.id)
    assert_equal 'Immediate', child1.reload.priority.name
    assert_equal 'Immediate', parent.reload.priority.name
    child3 = create_issue!(:priority => IssuePriority.find_by_name('Low'), :parent_id => parent.id)
    assert_equal 'Immediate', parent.reload.priority.name
    # Destroy a child
    child1.destroy
    assert_equal 'Low', parent.reload.priority.name
    # Update a child
    child3.reload.priority = IssuePriority.find_by_name('Normal')
    child3.save!
    assert_equal 'Normal', parent.reload.priority.name
  end

  def test_parent_dates_should_be_lowest_start_and_highest_due_dates
    parent = create_issue!
    create_issue!(:start_date => '2010-01-25', :due_date => '2010-02-15', :parent_id => parent.id)
    create_issue!(                             :due_date => '2010-02-13', :parent_id => parent.id)
    create_issue!(:start_date => '2010-02-01', :due_date => '2010-02-22', :parent_id => parent.id)
    parent.reload
    assert_equal Date.parse('2010-01-25'), parent.start_date
    assert_equal Date.parse('2010-02-22'), parent.due_date
  end

  def test_parent_done_ratio_should_be_average_done_ratio_of_leaves
    parent = create_issue!
    create_issue!(:done_ratio => 20, :parent_id => parent.id)
    assert_equal 20, parent.reload.done_ratio
    create_issue!(:done_ratio => 70, :parent_id => parent.id)
    assert_equal 45, parent.reload.done_ratio

    child = create_issue!(:done_ratio => 0, :parent_id => parent.id)
    assert_equal 30, parent.reload.done_ratio

    create_issue!(:done_ratio => 30, :parent_id => child.id)
    assert_equal 30, child.reload.done_ratio
    assert_equal 40, parent.reload.done_ratio
  end

  def test_parent_done_ratio_should_be_weighted_by_estimated_times_if_any
    parent = create_issue!
    create_issue!(:estimated_hours => 10, :done_ratio => 20, :parent_id => parent.id)
    assert_equal 20, parent.reload.done_ratio
    create_issue!(:estimated_hours => 20, :done_ratio => 50, :parent_id => parent.id)
    assert_equal (50 * 20 + 20 * 10) / 30, parent.reload.done_ratio
  end

  def test_parent_estimate_should_be_sum_of_leaves
    parent = create_issue!
    create_issue!(:estimated_hours => nil, :parent_id => parent.id)
    assert_equal nil, parent.reload.estimated_hours
    create_issue!(:estimated_hours => 5, :parent_id => parent.id)
    assert_equal 5, parent.reload.estimated_hours
    create_issue!(:estimated_hours => 7, :parent_id => parent.id)
    assert_equal 12, parent.reload.estimated_hours
  end

  def test_move_parent_updates_old_parent_attributes
    first_parent = create_issue!
    second_parent = create_issue!
    child = create_issue!(:estimated_hours => 5,
                          :parent_id => first_parent.id)
    assert_equal 5, first_parent.reload.estimated_hours
    child.update_attributes(:estimated_hours => 7,
                            :parent_id => second_parent.id)
    assert_equal 7, second_parent.reload.estimated_hours
    assert_nil first_parent.reload.estimated_hours
  end

  def test_project_copy_should_copy_issue_tree
    Project.delete_all # make sure unqiue identifiers
    p = Project.create!(:name => 'Tree copy', :identifier => 'tree-copy', :type_ids => [1, 2])
    i1 = create_issue!(:project_id => p.id, :subject => 'i1')
    i2 = create_issue!(:project_id => p.id, :subject => 'i2', :parent_id => i1.id)
    i3 = create_issue!(:project_id => p.id, :subject => 'i3', :parent_id => i1.id)
    i4 = create_issue!(:project_id => p.id, :subject => 'i4', :parent_id => i2.id)
    i5 = create_issue!(:project_id => p.id, :subject => 'i5')
    c = Project.new(:name => 'Copy', :identifier => 'copy', :type_ids => [1, 2])
    c.copy(p, :only => 'work_packages')
    c.reload

    assert_equal 5, c.work_packages.count
    ic1, ic2, ic3, ic4, ic5 = c.work_packages.reorder('subject')
    assert ic1.root?
    assert_equal ic1, ic2.parent
    assert_equal ic1, ic3.parent
    assert_equal ic2, ic4.parent
    assert ic5.root?
  end

  # Helper that creates an issue with default attributes
  def create_issue!(attributes={})
    (i = Issue.new.tap do |i|
      attr = { :project_id => 1, :type_id => 1, :author_id => 1, :subject => 'test' }.merge(attributes)
      i.force_attributes = attr
    end).save!
    i
  end
end

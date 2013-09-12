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

class IssueRelationTest < ActiveSupport::TestCase
  include MiniTest::Assertions # refute

  fixtures :all

  def test_create
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = IssueRelation.new :issue_from => from, :issue_to => to, :relation_type => IssueRelation::TYPE_PRECEDES
    assert relation.save
    relation.reload
    assert_equal IssueRelation::TYPE_PRECEDES, relation.relation_type
    assert_equal from, relation.issue_from
    assert_equal to, relation.issue_to
  end

  def test_follows_relation_should_be_reversed
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = IssueRelation.new :issue_from => from, :issue_to => to, :relation_type => IssueRelation::TYPE_FOLLOWS
    assert relation.save
    relation.reload
    assert_equal IssueRelation::TYPE_PRECEDES, relation.relation_type
    assert_equal to, relation.issue_from
    assert_equal from, relation.issue_to
  end

  def test_follows_relation_should_not_be_reversed_if_validation_fails
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = IssueRelation.new :issue_from => from, :issue_to => to, :relation_type => IssueRelation::TYPE_FOLLOWS, :delay => 'xx'
    assert !relation.save
    assert_equal IssueRelation::TYPE_FOLLOWS, relation.relation_type
    assert_equal from, relation.issue_from
    assert_equal to, relation.issue_to
  end

  def test_relation_type_for
    from = WorkPackage.find(1)
    to = WorkPackage.find(2)

    relation = IssueRelation.new :issue_from => from, :issue_to => to, :relation_type => IssueRelation::TYPE_PRECEDES
    assert_equal IssueRelation::TYPE_PRECEDES, relation.relation_type_for(from)
    assert_equal IssueRelation::TYPE_FOLLOWS, relation.relation_type_for(to)
  end

  def test_set_issue_to_dates_without_issue_to
    r = IssueRelation.new(:issue_from => WorkPackage.new(:start_date => Date.today), :relation_type => IssueRelation::TYPE_PRECEDES, :delay => 1)
    assert_nil r.set_issue_to_dates
  end

  def test_set_issue_to_dates_without_issues
    r = IssueRelation.new(:relation_type => IssueRelation::TYPE_PRECEDES, :delay => 1)
    assert_nil r.set_issue_to_dates
  end

  def test_validates_circular_dependency
    IssueRelation.delete_all
    assert IssueRelation.create!(:issue_from => WorkPackage.find(1), :issue_to => WorkPackage.find(2), :relation_type => IssueRelation::TYPE_PRECEDES)
    assert IssueRelation.create!(:issue_from => WorkPackage.find(2), :issue_to => WorkPackage.find(3), :relation_type => IssueRelation::TYPE_PRECEDES)
    r = IssueRelation.new(:issue_from => WorkPackage.find(3), :issue_to => WorkPackage.find(1), :relation_type => IssueRelation::TYPE_PRECEDES)
    assert !r.save
    refute_empty r.errors[:base]
  end
end

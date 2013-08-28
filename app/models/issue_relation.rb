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

class IssueRelation < ActiveRecord::Base
  belongs_to :issue_from, :class_name => 'WorkPackage', :foreign_key => 'issue_from_id'
  belongs_to :issue_to, :class_name => 'WorkPackage', :foreign_key => 'issue_to_id'

  scope :of_issue, ->(issue) { where('issue_from_id = ? OR issue_to_id = ?', issue, issue) }

  TYPE_RELATES      = "relates"
  TYPE_DUPLICATES   = "duplicates"
  TYPE_DUPLICATED   = "duplicated"
  TYPE_BLOCKS       = "blocks"
  TYPE_BLOCKED      = "blocked"
  TYPE_PRECEDES     = "precedes"
  TYPE_FOLLOWS      = "follows"

  TYPES = { TYPE_RELATES =>     { :name => :label_relates_to, :sym_name => :label_relates_to, :order => 1, :sym => TYPE_RELATES },
            TYPE_DUPLICATES =>  { :name => :label_duplicates, :sym_name => :label_duplicated_by, :order => 2, :sym => TYPE_DUPLICATED },
            TYPE_DUPLICATED =>  { :name => :label_duplicated_by, :sym_name => :label_duplicates, :order => 3, :sym => TYPE_DUPLICATES, :reverse => TYPE_DUPLICATES },
            TYPE_BLOCKS =>      { :name => :label_blocks, :sym_name => :label_blocked_by, :order => 4, :sym => TYPE_BLOCKED },
            TYPE_BLOCKED =>     { :name => :label_blocked_by, :sym_name => :label_blocks, :order => 5, :sym => TYPE_BLOCKS, :reverse => TYPE_BLOCKS },
            TYPE_PRECEDES =>    { :name => :label_precedes, :sym_name => :label_follows, :order => 6, :sym => TYPE_FOLLOWS },
            TYPE_FOLLOWS =>     { :name => :label_follows, :sym_name => :label_precedes, :order => 7, :sym => TYPE_PRECEDES, :reverse => TYPE_PRECEDES }
          }.freeze

  validates_presence_of :issue_from, :issue_to, :relation_type
  validates_inclusion_of :relation_type, :in => TYPES.keys
  validates_numericality_of :delay, :allow_nil => true
  validates_uniqueness_of :issue_to_id, :scope => :issue_from_id

  validate :validate_sanity_of_relation

  before_save :update_schedule

  attr_protected :issue_from_id, :issue_to_id

  def validate_sanity_of_relation
    if issue_from && issue_to
      errors.add :issue_to_id, :invalid if issue_from_id == issue_to_id
      errors.add :issue_to_id, :not_same_project unless issue_from.project_id == issue_to.project_id || Setting.cross_project_issue_relations?
      errors.add :base, :circular_dependency if issue_to.all_dependent_issues.include? issue_from
      errors.add :base, :cant_link_a_work_package_with_a_descendant if issue_from.is_descendant_of?(issue_to) || issue_from.is_ancestor_of?(issue_to)
    end
  end

  def other_issue(issue)
    (self.issue_from_id == issue.id) ? issue_to : issue_from
  end

  # Returns the relation type for +issue+
  def relation_type_for(issue)
    if TYPES[relation_type]
      if self.issue_from_id == issue.id
        relation_type
      else
        TYPES[relation_type][:sym]
      end
    end
  end

  def label_for(issue)
    TYPES[relation_type] ? TYPES[relation_type][(self.issue_from_id == issue.id) ? :name : :sym_name] : :unknow
  end

  def update_schedule
    reverse_if_needed

    if TYPE_PRECEDES == relation_type
      self.delay ||= 0
    else
      self.delay = nil
    end
    set_issue_to_dates
  end

  def set_issue_to_dates
    soonest_start = self.successor_soonest_start
    if soonest_start && issue_to
      issue_to.reschedule_after(soonest_start)
    end
  end

  def successor_soonest_start
    if (TYPE_PRECEDES == self.relation_type) && delay && issue_from && (issue_from.start_date || issue_from.due_date)
      (issue_from.due_date || issue_from.start_date) + 1 + delay
    end
  end

  def <=>(relation)
    TYPES[self.relation_type][:order] <=> TYPES[relation.relation_type][:order]
  end

  # delay is an attribute of IssueRelation but its getter is masked by delayed_job's #delay method
  # here we overwrite dj's delay method with the one reading the attribute
  # since we don't plan to use dj with IssueRelation objects, this should be fine
  def delay
    self[:delay]
  end

  private

  # Reverses the relation if needed so that it gets stored in the proper way
  def reverse_if_needed
    if TYPES.has_key?(relation_type) && TYPES[relation_type][:reverse]
      issue_tmp = issue_to
      self.issue_to = issue_from
      self.issue_from = issue_tmp
      self.relation_type = TYPES[relation_type][:reverse]
    end
  end
end

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

class IssueStatus < ActiveRecord::Base
  before_destroy :check_integrity
  has_many :workflows, :foreign_key => "old_status_id"
  acts_as_list

  before_destroy :delete_workflows

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30
  validates_inclusion_of :default_done_ratio, :in => 0..100, :allow_nil => true

  after_save :unmark_old_default_value, :if => :is_default?

  def unmark_old_default_value
    IssueStatus.update_all("is_default=#{connection.quoted_false}", ['id <> ?', id])
  end

  # Returns the default status for new issues
  def self.default
    find(:first, :conditions =>["is_default=?", true])
  end

  # Update all the +Issues+ setting their done_ratio to the value of their +IssueStatus+
  def self.update_issue_done_ratios
    if WorkPackage.use_status_for_done_ratio?
      IssueStatus.find(:all, :conditions => ["default_done_ratio >= 0"]).each do |status|
        WorkPackage.update_all(["done_ratio = ?", status.default_done_ratio],
                         ["status_id = ?", status.id])
      end
    end

    return WorkPackage.use_status_for_done_ratio?
  end

  # Returns an array of all statuses the given role can switch to
  # Uses association cache when called more than one time
  def new_statuses_allowed_to(roles, type, author=false, assignee=false)
    if roles && type
      role_ids = roles.collect(&:id)
      transitions = workflows.select do |w|
        role_ids.include?(w.role_id) &&
        w.type_id == type.id &&
        (author || !w.author) &&
        (assignee || !w.assignee)
      end
      transitions.collect{|w| w.new_status}.uniq.compact.sort
    else
      []
    end
  end

  # Same thing as above but uses a database query
  # More efficient than the previous method if called just once
  def find_new_statuses_allowed_to(roles, type, author=false, assignee=false)
    if roles && type
      conditions = {:role_id => roles.collect(&:id), :type_id => type.id}
      conditions[:author] = false unless author
      conditions[:assignee] = false unless assignee

      workflows.find(:all,
                     :include => :new_status,
                     :conditions => conditions).collect{|w| w.new_status}.compact.sort
    else
      []
    end
  end

  def <=>(status)
    position <=> status.position
  end

  def to_s; name end

private
  def check_integrity
    raise "Can't delete status" if WorkPackage.find(:first, :conditions => ["status_id=?", self.id])
  end

  # Deletes associated workflows
  def delete_workflows
    Workflow.delete_all(["old_status_id = :id OR new_status_id = :id", {:id => id}])
  end
end

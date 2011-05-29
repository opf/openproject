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

class IssueStatus < ActiveRecord::Base
  before_destroy :check_integrity  
  has_many :workflows, :foreign_key => "old_status_id"
  acts_as_list
  
  before_destroy :delete_workflows

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30
  validates_inclusion_of :default_done_ratio, :in => 0..100, :allow_nil => true

  def after_save
    IssueStatus.update_all("is_default=#{connection.quoted_false}", ['id <> ?', id]) if self.is_default?
  end  
  
  # Returns the default status for new issues
  def self.default
    find(:first, :conditions =>["is_default=?", true])
  end
  
  # Update all the +Issues+ setting their done_ratio to the value of their +IssueStatus+
  def self.update_issue_done_ratios
    if Issue.use_status_for_done_ratio?
      IssueStatus.find(:all, :conditions => ["default_done_ratio >= 0"]).each do |status|
        Issue.update_all(["done_ratio = ?", status.default_done_ratio],
                         ["status_id = ?", status.id])
      end
    end

    return Issue.use_status_for_done_ratio?
  end

  # Returns an array of all statuses the given role can switch to
  # Uses association cache when called more than one time
  def new_statuses_allowed_to(roles, tracker, author=false, assignee=false)
    if roles && tracker
      role_ids = roles.collect(&:id)
      transitions = workflows.select do |w|
        role_ids.include?(w.role_id) &&
        w.tracker_id == tracker.id && 
        (author || !w.author) &&
        (assignee || !w.assignee)
      end
      transitions.collect{|w| w.new_status}.compact.sort
    else
      []
    end
  end
  
  # Same thing as above but uses a database query
  # More efficient than the previous method if called just once
  def find_new_statuses_allowed_to(roles, tracker, author=false, assignee=false)
    if roles && tracker
      conditions = {:role_id => roles.collect(&:id), :tracker_id => tracker.id}
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
    raise "Can't delete status" if Issue.find(:first, :conditions => ["status_id=?", self.id])
  end
  
  # Deletes associated workflows
  def delete_workflows
    Workflow.delete_all(["old_status_id = :id OR new_status_id = :id", {:id => id}])
  end
end

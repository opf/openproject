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

class Tracker < ActiveRecord::Base
  before_destroy :check_integrity  
  has_many :issues
  has_many :workflows, :dependent => :delete_all do
    def copy(source_tracker)
      Workflow.copy(source_tracker, nil, proxy_owner, nil)
    end
  end
  
  has_and_belongs_to_many :projects
  has_and_belongs_to_many :custom_fields, :class_name => 'IssueCustomField', :join_table => "#{table_name_prefix}custom_fields_trackers#{table_name_suffix}", :association_foreign_key => 'custom_field_id'
  acts_as_list

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  def to_s; name end
  
  def <=>(tracker)
    name <=> tracker.name
  end

  def self.all
    find(:all, :order => 'position')
  end
  
  # Returns an array of IssueStatus that are used
  # in the tracker's workflows
  def issue_statuses
    if @issue_statuses
      return @issue_statuses 
    elsif new_record?
      return []
    end
    
    ids = Workflow.
            connection.select_rows("SELECT DISTINCT old_status_id, new_status_id FROM #{Workflow.table_name} WHERE tracker_id = #{id}").
            flatten.
            uniq
    
    @issue_statuses = IssueStatus.find_all_by_id(ids).sort
  end
  
private
  def check_integrity
    raise "Can't delete tracker" if Issue.find(:first, :conditions => ["tracker_id=?", self.id])
  end
end

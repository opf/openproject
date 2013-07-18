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

class CreateProjectsTrackers < ActiveRecord::Migration

  class Tracker < ActiveRecord::Base
    before_destroy :check_integrity
    has_many :issues
    has_many :workflows, :dependent => :delete_all do
      def copy(source_tracker)
        Workflow.copy(source_tracker, nil, proxy_association.owner, nil)
      end
    end

    has_and_belongs_to_many :projects
    has_and_belongs_to_many :custom_fields, :class_name => 'WorkPackageCustomField', :join_table => "#{table_name_prefix}custom_fields_trackers#{table_name_suffix}", :association_foreign_key => 'custom_field_id'
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

  def self.up

    Object.const_set("Tracker", AddTrackerPosition::Tracker)

    create_table :projects_trackers, :id => false do |t|
      t.column :project_id, :integer, :default => 0, :null => false
      t.column :tracker_id, :integer, :default => 0, :null => false
    end
    add_index :projects_trackers, :project_id, :name => :projects_trackers_project_id

    # Associates all trackers to all projects (as it was before)
    tracker_ids = Tracker.find(:all).collect(&:id)
    Project.find(:all).each do |project|
      project.tracker_ids = tracker_ids
    end

    Object.send(:remove_const, :Tracker)
  end

  def self.down
    drop_table :projects_trackers
  end
end

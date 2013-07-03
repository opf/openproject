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

# While loading the Issue class below, we lazy load the Project class. Which itself need Issue.
# So we create an 'emtpy' Issue class first, to make Project happy.

class WorkPackage < ActiveRecord::Base

  include NestedAttributesForApi

  belongs_to :project
  belongs_to :tracker
  belongs_to :status, :class_name => 'IssueStatus', :foreign_key => 'status_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :responsible, :class_name => "User", :foreign_key => "responsible_id"
  belongs_to :fixed_version, :class_name => 'Version', :foreign_key => 'fixed_version_id'
  belongs_to :priority, :class_name => 'IssuePriority', :foreign_key => 'priority_id'
  belongs_to :category, :class_name => 'IssueCategory', :foreign_key => 'category_id'

  belongs_to :planning_element_type,   :class_name  => "PlanningElementType",
                                       :foreign_key => 'planning_element_type_id'
  belongs_to :planning_element_status, :class_name  => "PlanningElementStatus",
                                       :foreign_key => 'planning_element_status_id'

  has_many :time_entries, :dependent => :delete_all

  scope :recently_updated, :order => "#{WorkPackage.table_name}.updated_at DESC"
  scope :visible, lambda {|*args| { :include => :project,
                                    :conditions => WorkPackage.visible_condition(args.first || User.current) } }
  scope :without_deleted, :conditions => "#{WorkPackage.quoted_table_name}.deleted_at IS NULL"
  scope :deleted, :conditions => "#{WorkPackage.quoted_table_name}.deleted_at IS NOT NULL"

  acts_as_watchable

  acts_as_nested_set :scope => 'root_id', :dependent => :destroy
  acts_as_customizable

  acts_as_searchable :columns => ['subject', "#{table_name}.description", "#{Journal.table_name}.notes"],
                     :include => [:project, :journals],
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.id"

  ##################### WARNING #####################
  # Do not change the order of acts_as_attachable   #
  # and acts_as_journalized!                        #
  #                                                 #
  # This order ensures that no journal entries are  #
  # written after a project is destroyed.           #
  #                                                 #
  # See test/unit/project_test.rb                   #
  # test_destroying_root_projects_should_clear_data #
  # for details.                                    #
  ###################################################
  acts_as_attachable :after_remove => :attachment_removed

  acts_as_journalized :event_title => Proc.new {|o| "#{o.tracker.name} ##{o.journaled_id} (#{o.status}): #{o.subject}"},
                      :event_type => Proc.new {|o|
                                                t = 'work_package'
                                                if o.changed_data.empty?
                                                  t << '-note' unless o.initial?
                                                else
                                                  t << (IssueStatus.find_by_id(o.new_value_for(:status_id)).try(:is_closed?) ? '-closed' : '-edit')
                                                end
                                                t },
                      :except => ["root_id"]

  register_on_journal_formatter(:id, 'parent_id')
  register_on_journal_formatter(:fraction, 'estimated_hours')
  register_on_journal_formatter(:decimal, 'done_ratio')
  register_on_journal_formatter(:diff, 'description')
  register_on_journal_formatter(:attachment, /attachments_?\d+/)
  register_on_journal_formatter(:custom_field, /custom_values\d+/)

  # Joined
  register_on_journal_formatter :named_association, :parent_id, :project_id,
                                                    :status_id, :tracker_id,
                                                    :assigned_to_id, :priority_id,
                                                    :category_id, :fixed_version_id,
                                                    :planning_element_type_id,
                                                    :planning_element_status_id,
                                                    :responsible_id
  register_on_journal_formatter :datetime,          :start_date, :end_date, :due_date, :deleted_at

  # By planning element
  register_on_journal_formatter :plaintext,         :subject,
                                                    :planning_element_status_comment
                                                    :responsible_id
  register_on_journal_formatter :scenario_date,     /^scenario_(\d+)_(start|end)_date$/

  # Returns a SQL conditions string used to find all work units visible by the specified user
  def self.visible_condition(user, options={})
    Project.allowed_to_condition(user, :view_work_packages, options)
  end

  WorkPackageJournal.class_eval do
    # Shortcut
    def new_status
      if details.keys.include? 'status_id'
        (newval = details['status_id'].last) ? IssueStatus.find_by_id(newval.to_i) : nil
      end
    end
  end

  # Returns true if usr or current user is allowed to view the issue
  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_work_packages, self.project)
  end

  def copy_from(arg)
    work_package = arg.is_a?(WorkPackage) ? arg : WorkPackage.visible.find(arg)
    # attributes don't come from form, so it's save to force assign
    self.force_attributes = work_package.attributes.dup.except("id", "root_id", "parent_id", "lft", "rgt", "created_at", "updated_at")
    self.parent_issue_id = work_package.parent_id if work_package.parent_id
    self.custom_field_values = work_package.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
    self.status = work_package.status
    self
  end

  # ACTS AS ATTACHABLE
  # Callback on attachment deletion
  def attachment_removed(obj)
    init_journal(User.current)
    create_journal
    last_journal.update_attribute(:changed_data, { "attachments_#{obj.id}" => [obj.filename, nil] })
  end

  # ACTS AS JOURNALIZED
  def activity_type
    "work_packages"
  end

  # Users the work_package can be assigned to
  delegate :assignable_users, :to => :project

  # Versions that the issue can be assigned to
  def assignable_versions
    @assignable_versions ||= (project.shared_versions.open + [Version.find_by_id(fixed_version_id_was)]).compact.uniq.sort
  end

  def kind
    if self.is_a? Issue
      return tracker
    elsif self.is_a? PlanningElement
      return planning_element_type
    end
  end

  def to_s
    "#{(kind.nil?) ? '' : kind.name} ##{id}: #{subject}"
  end
end

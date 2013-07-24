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

  #TODO Remove alternate inheritance column name once single table
  # inheritance is no longer needed. The need for a different column name
  # comes from Trackers becoming Types.
  self.inheritance_column = :sti_type

  include NestedAttributesForApi

  belongs_to :project
  belongs_to :type
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
  has_many :relations_from, :class_name => 'IssueRelation', :foreign_key => 'issue_from_id', :dependent => :delete_all
  has_many :relations_to, :class_name => 'IssueRelation', :foreign_key => 'issue_to_id', :dependent => :delete_all

  scope :recently_updated, :order => "#{WorkPackage.table_name}.updated_at DESC"
  scope :visible, lambda {|*args| { :include => :project,
                                    :conditions => WorkPackage.visible_condition(args.first ||
                                                                                 User.current) } }
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

  acts_as_journalized :event_title => Proc.new {|o| "#{ o.to_s }"},
                      :event_type => (Proc.new do |o|
                        t = 'work_package'
                        if o.changed_data.empty?
                          t << '-note' unless o.initial?
                        else
                          t << (IssueStatus.find_by_id(
                            o.new_value_for(:status_id)).try(:is_closed?) ? '-closed' : '-edit'
                          )
                        end
                        t
                      end),
                      :except => ["root_id"]

  register_on_journal_formatter(:id, 'parent_id')
  register_on_journal_formatter(:fraction, 'estimated_hours')
  register_on_journal_formatter(:decimal, 'done_ratio')
  register_on_journal_formatter(:diff, 'description')
  register_on_journal_formatter(:attachment, /attachments_?\d+/)
  register_on_journal_formatter(:custom_field, /custom_values\d+/)

  # Joined
  register_on_journal_formatter :named_association, :parent_id, :project_id,
                                                    :status_id, :type_id,
                                                    :assigned_to_id, :priority_id,
                                                    :category_id, :fixed_version_id,
                                                    :planning_element_type_id,
                                                    :planning_element_status_id,
                                                    :author_id, :responsible_id
  register_on_journal_formatter :datetime,          :start_date, :due_date, :deleted_at

  # By planning element
  register_on_journal_formatter :plaintext,         :subject,
                                                    :planning_element_status_comment,
                                                    :responsible_id
  register_on_journal_formatter :scenario_date,     /^scenario_(\d+)_(start|due)_date$/

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

  def self.use_status_for_done_ratio?
    Setting.issue_done_ratio == 'issue_status'
  end

  def self.use_field_for_done_ratio?
    Setting.issue_done_ratio == 'issue_field'
  end

  # Returns true if usr or current user is allowed to view the issue
  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_work_packages, self.project)
  end

  def copy_from(arg, options = {})

    merged_options = { :exclude => ["id",
                                    "root_id",
                                    "parent_id",
                                    "lft",
                                    "rgt",
                                    "type", # type_id is in options, type is for STI.
                                    "created_at",
                                    "updated_at"] + (options[:exclude]|| []).map(&:to_s) }

    work_package = arg.is_a?(WorkPackage) ? arg : WorkPackage.visible.find(arg)

    # attributes don't come from form, so it's save to force assign
    self.force_attributes = work_package.attributes.dup.except(*merged_options[:exclude])
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

  # RELATIONS
  def delete_relations(work_package)
    unless Setting.cross_project_issue_relations?
      work_package.relations_from.clear
      work_package.relations_to.clear
    end
  end

  def delete_invalid_relations(invalid_work_packages)
    invalid_work_package.each do |work_package|
      work_package.relations.each do |relation|
        relation.destroy unless relation.valid?
      end
    end
  end

  # Returns true if this work package is blocked by another work package that is still open
  def blocked?
    !relations_to.detect {|ir| ir.relation_type == 'blocks' && !ir.issue_from.closed?}.nil?
  end

  def relations
    IssueRelation.of_issue(self)
  end

  def relation(id)
    IssueRelation.of_issue(self).find(id)
  end

  def new_relation
    self.relations_from.build
  end

  def add_time_entry
    time_entries.build(:project => project,
                       :work_package => self)
  end

  def all_dependent_issues(except=[])
    except << self
    dependencies = []
    relations_from.each do |relation|
      if relation.issue_to && !except.include?(relation.issue_to)
        dependencies << relation.issue_to
        dependencies += relation.issue_to.all_dependent_issues(except)
      end
    end
    dependencies
  end

  # Returns an array of issues that duplicate this one
  def duplicates
    relations_to.select {|r| r.relation_type == IssueRelation::TYPE_DUPLICATES}.collect {|r| r.issue_from}
  end

  def soonest_start
    @soonest_start ||= (
        relations_to.collect{|relation| relation.successor_soonest_start} +
        ancestors.collect(&:soonest_start)
      ).compact.max
  end

  # Updates start/due dates of following issues
  def reschedule_following_issues
    if start_date_changed? || due_date_changed?
      relations_from.each do |relation|
        relation.set_issue_to_dates
      end
    end
  end

  # Users the work_package can be assigned to
  delegate :assignable_users, :to => :project

  # Versions that the issue can be assigned to
  def assignable_versions
    @assignable_versions ||= (project.shared_versions.open + [Version.find_by_id(fixed_version_id_was)]).compact.uniq.sort
  end

  def kind
    if self.is_a? Issue
      return type
    elsif self.is_a? PlanningElement
      return planning_element_type
    end
  end

  def to_s
    "#{(kind.nil?) ? '' : "#{kind.name} "}##{id}: #{subject}"
  end

  # Return true if the work_package is closed, otherwise false
  def closed?
    self.status.nil? || self.status.is_closed?
  end

  # TODO: move into Business Object and rename to update
  # update for now is a private method defined by AR
  def update_by(user, attributes)
    init_journal(user, attributes.delete(:notes)) if attributes[:notes]

    update_attributes(attributes)
  end

  def recalculate_attributes_for(work_package_id)
    if work_package_id.is_a? WorkPackage
      p = work_package_id
    else
      p = WorkPackage.find_by_id(work_package_id)
    end

    if p
      # priority = highest priority of children
      if priority_position = p.children.joins(:priority).maximum("#{IssuePriority.table_name}.position")
        p.priority = IssuePriority.find_by_position(priority_position)
      end

      # start/due dates = lowest/highest dates of children
      p.start_date = p.children.minimum(:start_date)
      p.due_date = p.children.maximum(:due_date)
      if p.start_date && p.due_date && p.due_date < p.start_date
        p.start_date, p.due_date = p.due_date, p.start_date
      end

      # done ratio = weighted average ratio of leaves
      unless WorkPackage.use_status_for_done_ratio? && p.status && p.status.default_done_ratio
        leaves_count = p.leaves.count
        if leaves_count > 0
          average = p.leaves.average(:estimated_hours).to_f
          if average == 0
            average = 1
          end
          done = p.leaves.joins(:status).sum("COALESCE(estimated_hours, #{average}) * (CASE WHEN is_closed = #{connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)").to_f
          progress = done / (average * leaves_count)
          p.done_ratio = progress.round
        end
      end

      # estimate = sum of leaves estimates
      p.estimated_hours = p.leaves.sum(:estimated_hours).to_f
      p.estimated_hours = nil if p.estimated_hours == 0.0

      # ancestors will be recursively updated
      p.save(:validate => false) if p.changed?
    end
  end

  # This is a dummy implementation that is currently overwritten
  # by issue
  # Adapt once tracker/type is migrated
  def new_statuses_allowed_to(user, include_default = false)
    IssueStatus.all
  end

  def self.use_status_for_done_ratio?
    Setting.issue_done_ratio == 'issue_status'
  end

end

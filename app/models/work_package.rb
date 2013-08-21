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

  belongs_to :planning_element_status, :class_name  => "PlanningElementStatus",
                                       :foreign_key => 'planning_element_status_id'

  has_many :time_entries, :dependent => :delete_all
  has_many :relations_from, :class_name => 'IssueRelation', :foreign_key => 'issue_from_id', :dependent => :delete_all
  has_many :relations_to, :class_name => 'IssueRelation', :foreign_key => 'issue_to_id', :dependent => :delete_all
  has_and_belongs_to_many :changesets,
                          :order => "#{Changeset.table_name}.committed_on ASC, #{Changeset.table_name}.id ASC"


  scope :recently_updated, :order => "#{WorkPackage.table_name}.updated_at DESC"
  scope :visible, lambda {|*args| { :include => :project,
                                    :conditions => WorkPackage.visible_condition(args.first ||
                                                                                 User.current) } }
  scope :without_deleted, :conditions => "#{WorkPackage.quoted_table_name}.deleted_at IS NULL"
  scope :deleted, :conditions => "#{WorkPackage.quoted_table_name}.deleted_at IS NOT NULL"

  after_initialize :set_default_values

  acts_as_watchable

  before_save :store_former_parent_id
  include OpenProject::NestedSet::WithRootIdScope
  after_save :reschedule_following_issues,
             :update_parent_attributes,
             :create_alternate_date

  after_move :remove_invalid_relations,
             :recalculate_attributes_for_former_parent

  after_destroy :update_parent_attributes

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
  acts_as_attachable :after_add => :attachments_changed,
                     :after_remove => :attachments_changed

  # This one is here only to ease reading
  module JournalizedProcs
    def self.event_title
      Proc.new do |data|
        journal = data.journal
        work_package = journal.journable

        title = work_package.to_s
        title << " (#{work_package.status.name})" if work_package.status.present?

        title
      end
    end

    def self.event_type
      Proc.new do |data|
        journal = data.journal
        t = 'work_package'

        t << if journal.changed_data.empty? && !journal.initial?
               '-note'
             else
               status = IssueStatus.find_by_id(journal.new_value_for(:status_id))

               status.try(:is_closed?) ? '-closed' : '-edit'
             end

        t
      end
    end
  end

  acts_as_journalized :event_title => JournalizedProcs.event_title,
                      :event_type => JournalizedProcs.event_type,
                      :except => ["root_id"],
                      :activity_find_options => { :include => [:status, :type] }

  register_on_journal_formatter(:id, 'parent_id')
  register_on_journal_formatter(:fraction, 'estimated_hours')
  register_on_journal_formatter(:decimal, 'done_ratio')
  register_on_journal_formatter(:diff, 'description')
  register_on_journal_formatter(:attachment, /attachments_?\d+/)
  register_on_journal_formatter(:custom_field, /custom_fields_\d+/)

  # Joined
  register_on_journal_formatter :named_association, :parent_id, :project_id,
                                                    :status_id, :type_id,
                                                    :assigned_to_id, :priority_id,
                                                    :category_id, :fixed_version_id,
                                                    :planning_element_status_id,
                                                    :author_id, :responsible_id
  register_on_journal_formatter :datetime,          :start_date, :due_date, :deleted_at

  # By planning element
  register_on_journal_formatter :plaintext,         :subject,
                                                    :planning_element_status_comment,
                                                    :responsible_id
  register_on_journal_formatter :scenario_date,     /^scenario_(\d+)_(start|due)_date$/

  # acts_as_journalized will create an initial journal on wp creation
  # and touch the journaled object:
  # journal.rb:47
  #
  # This will result in optimistic locking increasing the lock_version attribute to 1.
  # In order to avoid stale object errors we reload the attributes in question
  # after the wp is created.
  # As after_create is run before after_save, and journal creation is triggered by an
  # after_save hook, we rely on after_save and a specific version here.
  after_save :reload_lock_and_timestamps, :if => Proc.new { |wp| wp.lock_version == 0 }

  # Returns a SQL conditions string used to find all work units visible by the specified user
  def self.visible_condition(user, options={})
    Project.allowed_to_condition(user, :view_work_packages, options)
  end

  def self.use_status_for_done_ratio?
    Setting.issue_done_ratio == 'issue_status'
  end

  def self.use_field_for_done_ratio?
    Setting.issue_done_ratio == 'issue_field'
  end

  # Returns true if usr or current user is allowed to view the work_package
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
    self.parent_id = work_package.parent_id if work_package.parent_id
    self.custom_field_values = work_package.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
    self.status = work_package.status
    self
  end

  # Returns true if the work_package is overdue
  def overdue?
    !due_date.nil? && (due_date < Date.today) && !status.is_closed?
  end

  # ACTS AS ATTACHABLE
  # Callback on attachment deletion
  def attachments_changed(obj)
    add_journal
    save!
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

  def trash
    unless new_record? or self.deleted_at
      self.children.each{|child| child.trash}

      self.reload
      self.deleted_at = Time.now
      self.save!
    end
    freeze
  end

  def restore!
    unless parent && parent.deleted?
      self.deleted_at = nil
      self.save
    else
      raise "You cannot restore an element whose parent is deleted. Restore the parent first!"
    end
  end

  def deleted?
    !!read_attribute(:deleted_at)
  end

  # Users the work_package can be assigned to
  delegate :assignable_users, :to => :project

  # Versions that the work_package can be assigned to
  def assignable_versions
    @assignable_versions ||= (project.shared_versions.open + [Version.find_by_id(fixed_version_id_was)]).compact.uniq.sort
  end

  def kind
    return type
  end

  def to_s
    "#{(kind.is_standard) ? l(:default_type) : "#{kind.name}"} ##{id}: #{subject}"
  end

  # Return true if the work_package is closed, otherwise false
  def closed?
    self.status.nil? || self.status.is_closed?
  end

  # Returns true if the work_package is overdue
  def overdue?
    !due_date.nil? && (due_date < Date.today) && !closed?
  end

  # TODO: move into Business Object and rename to update
  # update for now is a private method defined by AR
  def update_by!(user, attributes)
    raw_attachments = attributes.delete(:attachments)

    update_by(user, attributes)

    if save
      # as attach_files always saves an attachment right away
      # it is not possible to stage attaching and check for
      # valid. If this would be possible, we could check
      # for this along with update_attributes
      attachments = Attachment.attach_files(self, raw_attachments)
    end
  end

  def update_by(user, attributes)
    add_journal(user, attributes.delete(:notes)) if attributes[:notes]

    add_time_entry_for(user, attributes.delete(:time_entry))
    attributes.delete(:attachments)

    self.attributes = attributes
  end

  def is_milestone?
    type && type.is_milestone?
  end

  # Returns an array of status that user is able to apply
  def new_statuses_allowed_to(user, include_default=false)
    return [] if status.nil?

    statuses = status.find_new_statuses_allowed_to(
      user.roles_for_project(project),
      type,
      author == user,
      assigned_to_id_changed? ? assigned_to_id_was == user.id : assigned_to_id == user.id
      )
    statuses << status unless statuses.empty?
    statuses << IssueStatus.default if include_default
    statuses = statuses.uniq.sort
    blocked? ? statuses.reject {|s| s.is_closed?} : statuses
  end

  def self.use_status_for_done_ratio?
    Setting.issue_done_ratio == 'issue_status'
  end

  # Returns the total number of hours spent on this issue and its descendants
  #
  # Example:
  #   spent_hours => 0.0
  #   spent_hours => 50.2
  def spent_hours
    @spent_hours ||= self_and_descendants.joins(:time_entries)
                                         .sum("#{TimeEntry.table_name}.hours").to_f || 0.0
  end

  # Moves/copies an work_package to a new project and type
  # Returns the moved/copied work_package on success, false on failure
  def move_to_project(*args)
    ret = WorkPackage.transaction do
      move_to_project_without_transaction(*args) || raise(ActiveRecord::Rollback)
    end || false
  end

  protected

  def recalculate_attributes_for(work_package_id)
    p = if work_package_id.is_a? WorkPackage
          work_package_id
        else
          WorkPackage.find_by_id(work_package_id)
        end

    return unless p

    p.inherit_priority_from_children

    p.inherit_dates_from_children

    p.inherit_done_ratio_from_leaves

    p.inherit_estimated_hours_from_leaves

    # ancestors will be recursively updated
    if p.changed?
      p.journal_notes = I18n.t('timelines.planning_element_updated_automatically_by_child_changes', :child => "*#{id}")

      # Ancestors will be updated by parent's after_save hook.
      p.save(:validate => false)
    end
  end

  def update_parent_attributes
    recalculate_attributes_for(parent_id) if parent_id.present?
  end

  def inherit_priority_from_children
    # priority = highest priority of children
    if priority_position = children.joins(:priority).maximum("#{IssuePriority.table_name}.position")
      self.priority = IssuePriority.find_by_position(priority_position)
    end
  end

  def inherit_dates_from_children
    active_children = children.without_deleted

    unless active_children.empty?
      self.start_date = [active_children.minimum(:start_date), active_children.minimum(:due_date)].compact.min
      self.due_date   = [active_children.maximum(:start_date), active_children.maximum(:due_date)].compact.max
    end
  end

  def inherit_done_ratio_from_leaves
    # done ratio = weighted average ratio of leaves
    unless WorkPackage.use_status_for_done_ratio? && status && status.default_done_ratio
      leaves_count = leaves.count
      if leaves_count > 0
        average = leaves.average(:estimated_hours).to_f
        if average == 0
          average = 1
        end
        done = leaves.joins(:status).sum("COALESCE(estimated_hours, #{average}) * (CASE WHEN is_closed = #{connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)").to_f
        progress = done / (average * leaves_count)

        self.done_ratio = progress.round
      end
    end
  end

  def inherit_estimated_hours_from_leaves
    # estimate = sum of leaves estimates
    self.estimated_hours = leaves.sum(:estimated_hours).to_f
    self.estimated_hours = nil if estimated_hours == 0.0
  end

  def store_former_parent_id
    @former_parent_id = parent_id_changed? ? parent_id_was : false
    true # force callback to return true
  end

  def remove_invalid_relations
    # delete invalid relations of all descendants
    self_and_descendants.each do |issue|
      issue.relations.each do |relation|
        relation.destroy unless relation.valid?
      end
    end
  end

  def recalculate_attributes_for_former_parent
    recalculate_attributes_for(@former_parent_id) if @former_parent_id
  end

  def reload_lock_and_timestamps
    reload(:select => [:lock_version, :created_at, :updated_at])
  end

  # Returns an array of projects that current user can move issues to
  def self.allowed_target_projects_on_move
    projects = []
    if User.current.admin?
      # admin is allowed to move issues to any active (visible) project
      projects = Project.visible.all
    elsif User.current.logged?
      if Role.non_member.allowed_to?(:move_work_packages)
        projects = Project.visible.all
      else
        User.current.memberships.each {|m| projects << m.project if m.roles.detect {|r| r.allowed_to?(:move_work_packages)}}
      end
    end
    projects
  end

  def move_to_project_without_transaction(new_project, new_type = nil, options = {})
    options ||= {}
    work_package = options[:copy] ? self.class.new.copy_from(self) : self

    if new_project && work_package.project_id != new_project.id
      delete_relations(work_package)
      # work_package is moved to another project
      # reassign to the category with same name if any
      new_category = work_package.category.nil? ? nil : new_project.issue_categories.find_by_name(work_package.category.name)
      work_package.category = new_category
      # Keep the fixed_version if it's still valid in the new_project
      unless new_project.shared_versions.include?(work_package.fixed_version)
        work_package.fixed_version = nil
      end
      work_package.project = new_project

      if !Setting.cross_project_issue_relations? &&
         parent && parent.project_id != project_id
        self.parent_id = nil
      end
    end
    if new_type
      work_package.type = new_type
      work_package.reset_custom_values!
    end
    # Allow bulk setting of attributes on the work_package
    if options[:attributes]
      work_package.attributes = options[:attributes]
    end
    if options[:copy]
      work_package.author = User.current
      work_package.custom_field_values = self.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
      work_package.status = if options[:attributes] && options[:attributes][:status_id]
                              IssueStatus.find_by_id(options[:attributes][:status_id])
                            else
                              self.status
                            end
    end
    if work_package.save
      unless options[:copy]
        # Manually update project_id on related time entries
        TimeEntry.update_all("project_id = #{new_project.id}", {:work_package_id => id})

        work_package.children.each do |child|
          unless child.move_to_project_without_transaction(new_project)
            # Move failed and transaction was rollback'd
            return false
          end
        end
      end
    else
      return false
    end
    work_package
  end

  private

  def set_default_values
    if new_record? # set default values for new records only
      self.status   ||= IssueStatus.default
      self.priority ||= IssuePriority.default
    end
  end

  private

  def add_time_entry_for(user, attributes)
    return if attributes.nil? || attributes.values.all?(&:blank?)

    attributes.reverse_merge!({ :user => user,
                                :spent_on => Date.today })

    time_entries.build(attributes)
  end

  def create_alternate_date
    # This is a hack.
    # It is required as long as alternate dates exist/are not moved up to work_packages.
    # Its purpose is to allow for setting the after_save filter in the correct order
    # before acts as journalized and the cleanup method reload_lock_and_timestamps.
    return true unless respond_to?(:alternate_dates)

    if start_date_changed? or due_date_changed?
      alternate_dates.create(:start_date => start_date, :due_date => due_date)
    end
  end
end

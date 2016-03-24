#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# While loading the Issue class below, we lazy load the Project class.
# Which itself need WorkPackage.
# So we create an 'empty' Issue class first, to make Project happy.

class WorkPackage < ActiveRecord::Base
  include WorkPackage::Validations
  include WorkPackage::SchedulingRules
  include WorkPackage::StatusTransitions
  include WorkPackage::AskBeforeDestruction
  include WorkPackage::TimeEntries

  include OpenProject::Journal::AttachmentHelper

  DONE_RATIO_OPTIONS = %w(field status disabled)
  ATTRIBS_WITH_VALUES_FROM_CHILDREN =
    %w(priority_id start_date due_date estimated_hours done_ratio)
  # <<< issues.rb <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  belongs_to :project
  belongs_to :type
  belongs_to :status, class_name: 'Status', foreign_key: 'status_id'
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :assigned_to, class_name: 'Principal', foreign_key: 'assigned_to_id'
  belongs_to :responsible, class_name: 'Principal', foreign_key: 'responsible_id'
  belongs_to :fixed_version, class_name: 'Version', foreign_key: 'fixed_version_id'
  belongs_to :priority, class_name: 'IssuePriority', foreign_key: 'priority_id'
  belongs_to :category, class_name: 'Category', foreign_key: 'category_id'

  has_many :time_entries, dependent: :delete_all
  has_many :relations_from, class_name: 'Relation', foreign_key: 'from_id', dependent: :delete_all
  has_many :relations_to, class_name: 'Relation', foreign_key: 'to_id', dependent: :delete_all
  has_and_belongs_to_many :changesets, -> {
    order("#{Changeset.table_name}.committed_on ASC, #{Changeset.table_name}.id ASC")
  }

  scope :recently_updated, ->() {
    # Specified as a String due to https://github.com/rails/rails/issues/15405
    # TODO: change to Hash on upgrade to Rails 4.1.
    order("#{WorkPackage.table_name}.updated_at DESC")
  }

  scope :visible, ->(*args) {
    includes(:project)
      .merge(Project.allowed_to(args.first || User.current, :view_work_packages))
  }

  scope :in_status, -> (*args) do
                      where(status_id: (args.first.respond_to?(:id) ? args.first.id : args.first))
                    end

  scope :for_projects, ->(projects) {
    where(project_id: projects)
  }

  scope :changed_since, ->(changed_since) {
    if changed_since
      where(["#{WorkPackage.table_name}.updated_at >= ?", changed_since])
    end
  }

  # >>> issues.rb >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  scope :open, ->() {
    includes(:status)
      .where(statuses: { is_closed: false  })
  }

  scope :with_limit, ->(limit) {
    limit(limit)
  }

  scope :on_active_project, -> {
    includes(:status, :project, :type)
      .where(projects: { status: Project::STATUS_ACTIVE })
  }

  scope :without_version, -> {
    where(fixed_version_id: nil)
  }

  scope :with_query, ->(query) {
    where(::Query.merge_conditions(query.statement))
  }

  scope :with_author, ->(author) {
    where(author_id: author.id)
  }

  # <<< issues.rb <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  after_initialize :set_default_values

  acts_as_watchable

  before_save :store_former_parent_id

  include OpenProject::NestedSet::WithRootIdScope

  after_save :reschedule_following_issues,
             :update_parent_attributes

  after_move :remove_invalid_relations,
             :recalculate_attributes_for_former_parent

  after_destroy :update_parent_attributes

  # >>> issues.rb >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  before_create :default_assign
  before_save :close_duplicates, :update_done_ratio_from_status
  before_destroy :remove_attachments
  # <<< issues.rb <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  acts_as_customizable

  acts_as_searchable columns: ['subject',
                               "#{table_name}.description",
                               "#{Journal.table_name}.notes"],
                     include: [:project, :journals],
                     references: [:projects, :journals],
                     date_column: "#{quoted_table_name}.created_at",
                     # sort by id so that limited eager loading doesn't break with postgresql
                     order_column: "#{table_name}.id"

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
  acts_as_attachable after_remove: :attachments_changed, order: "#{Attachment.table_name}.filename"

  after_validation :set_attachments_error_details,
                   if: lambda { |work_package| work_package.errors.messages.has_key? :attachments }

  associated_to_ask_before_destruction TimeEntry,
                                       ->(work_packages) {
                                         TimeEntry.on_work_packages(work_packages).count > 0
                                       },
                                       method(:cleanup_time_entries_before_destruction_of)

  acts_as_journalized except: ['root_id']

  # This one is here only to ease reading
  module JournalizedProcs
    def self.event_title
      Proc.new do |o|
        title = o.to_s
        title << " (#{o.status.name})" if o.status.present?

        title
      end
    end

    def self.event_name
      Proc.new do |o|
        I18n.t(o.event_type.underscore, scope: 'events')
      end
    end

    def self.event_type
      Proc.new do |o|
        journal = o.last_journal
        t = 'work_package'

        t << if journal && journal.details.empty? && !journal.initial?
               '-note'
             else
               status = Status.find_by(id: o.status_id)

               status.try(:is_closed?) ? '-closed' : '-edit'
             end
        t
      end
    end

    def self.event_url
      Proc.new do |o|
        { controller: :work_packages, action: :show, id: o.id }
      end
    end
  end

  acts_as_event title: JournalizedProcs.event_title,
                type: JournalizedProcs.event_type,
                name: JournalizedProcs.event_name,
                url: JournalizedProcs.event_url

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
  register_on_journal_formatter :datetime,          :start_date, :due_date

  # By planning element
  register_on_journal_formatter :plaintext,         :subject,
                                :planning_element_status_comment

  # acts_as_journalized will create an initial journal on wp creation
  # and touch the journaled object:
  # journal.rb:47
  #
  # This will result in optimistic locking increasing the lock_version attribute to 1.
  # In order to avoid stale object errors we reload the attributes in question
  # after the wp is created.
  # As after_create is run before after_save, and journal creation is triggered by an
  # after_save hook, we rely on after_save and a specific version here.
  after_save :reload_lock_and_timestamps, if: Proc.new { |wp| wp.lock_version == 0 }

  # Returns a SQL conditions string used to find all work units visible by the specified user
  def self.visible_condition(user, options = {})
    Project.allowed_to_condition(user, :view_work_packages, options)
  end

  def self.done_ratio_disabled?
    Setting.work_package_done_ratio == 'disabled'
  end

  def self.use_status_for_done_ratio?
    Setting.work_package_done_ratio == 'status'
  end

  def self.use_field_for_done_ratio?
    Setting.work_package_done_ratio == 'field'
  end

  # Returns true if usr or current user is allowed to view the work_package
  def visible?(usr = nil)
    (usr || User.current).allowed_to?(:view_work_packages, project)
  end

  def copy_from(arg, options = {})
    merged_options = { exclude: ['id',
                                 'root_id',
                                 'parent_id',
                                 'lft',
                                 'rgt',
                                 'type', # type_id is in options, type is for STI.
                                 'created_at',
                                 'updated_at'] + (options[:exclude] || []).map(&:to_s) }

    work_package = arg.is_a?(WorkPackage) ? arg : WorkPackage.visible.find(arg)

    # attributes don't come from form, so it's safe to force assign
    self.attributes = work_package.attributes.dup.except(*merged_options[:exclude])
    self.parent_id = work_package.parent_id if work_package.parent_id
    self.custom_field_values =
      work_package.custom_field_values.inject({}) do |h, v|
        h[v.custom_field_id] = v.value
        h
      end
    self.status = work_package.status

    work_package.watchers.each do |watcher|
      # This might be a problem once this method is used on existing work packages
      # then, the watchers are added, keeping preexisting watchers
      add_watcher(watcher.user) if watcher.user.active?
    end

    self
  end

  # Returns true if the work_package is overdue
  def overdue?
    !due_date.nil? && (due_date < Date.today) && !status.is_closed?
  end

  # ACTS AS JOURNALIZED
  def activity_type
    'work_packages'
  end

  # RELATIONS
  # Returns true if this work package is blocked by another work package that is still open
  def blocked?
    !relations_to.detect { |ir| ir.relation_type == 'blocks' && !ir.from.closed? }.nil?
  end

  def relations
    Relation.of_work_package(self)
  end

  def relation(id)
    Relation.of_work_package(self).find(id)
  end

  def new_relation
    relations_from.build
  end

  def add_time_entry(attributes = {})
    attributes.reverse_merge!(
      project: project,
      work_package: self
    )
    time_entries.build(attributes)
  end

  def move_time_entries(project)
    time_entries.update_all(project_id: project)
  end

  def all_dependent_packages(except = [])
    except << self
    dependencies = []
    relations_from.each do |relation|
      if relation.to && !except.include?(relation.to)
        dependencies << relation.to
        dependencies += relation.to.all_dependent_packages(except)
      end
    end
    dependencies
  end

  # Returns an array of issues that duplicate this one
  def duplicates
    relations_to.select { |r| r.relation_type == Relation::TYPE_DUPLICATES }.map(&:from)
  end

  def soonest_start
    @soonest_start ||= (
      self_and_ancestors.includes(relations_to: :from)
                        .where(relations: { relation_type: Relation::TYPE_PRECEDES })
                        .map(&:relations_to)
                        .flatten
                        .map(&:successor_soonest_start)
    ).compact.max
  end

  # Updates start/due dates of following issues
  def reschedule_following_issues
    if start_date_changed? || due_date_changed?
      relations_from.each(&:set_dates_of_target)
    end
  end

  # Users/groups the work_package can be assigned to
  extend Forwardable
  def_delegator :project, :possible_assignees, :assignable_assignees

  # Users the work_package can be assigned to
  def_delegator :project, :possible_responsibles, :assignable_responsibles

  # Versions that the work_package can be assigned to
  # A work_package can be assigned to:
  #   * any open, shared version of the project the wp belongs to
  #   * the version it was already assigned to
  #     (to make sure, that you can still update closed tickets)
  def assignable_versions
    @assignable_versions ||= begin
      current_version = fixed_version_id_changed? ? Version.find_by(id: fixed_version_id_was) : fixed_version
      (project.assignable_versions + [current_version]).compact.uniq.sort
    end
  end

  def kind
    type
  end

  def to_s
    "#{(kind.is_standard) ? '' : "#{kind.name}"} ##{id}: #{subject}"
  end

  # Return true if the work_package is closed, otherwise false
  def closed?
    status.nil? || status.is_closed?
  end

  # Returns true if the work_package is overdue
  def overdue?
    !due_date.nil? && (due_date < Date.today) && !closed?
  end

  def is_milestone?
    type && type.is_milestone?
  end

  # Overwriting awesome nested set here as it considers unpersisted work
  # packages to not be leaves.
  # https://github.com/collectiveidea/awesome_nested_set/blob/master/lib/awesome_nested_set/model.rb#L135
  # The OP workflow however requires to first create a WP before children can
  # be assigned to it. Unpersisted WPs are hence always leaves.
  def leaf?
    new_record? || super
  end

  # Returns an array of status that user is able to apply
  def new_statuses_allowed_to(user, include_default = false)
    return [] if status.nil?

    statuses = status.find_new_statuses_allowed_to(
      user.roles_for_project(project),
      type,
      author == user,
      assigned_to_id_changed? ? assigned_to_id_was == user.id : assigned_to_id == user.id
    )
    statuses << status unless statuses.empty?
    statuses << Status.default if include_default
    statuses = statuses.uniq.sort
    blocked? ? statuses.reject(&:is_closed?) : statuses
  end

  # >>> issues.rb >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  # Returns users that should be notified
  def recipients
    notified = project.notified_users
    # Author and assignee are always notified unless they have been
    # locked or don't want to be notified
    notified << author if author && author.active? && author.notify_about?(self)
    if assigned_to
      if assigned_to.is_a?(Group)
        notified += assigned_to.users.select { |u| u.active? && u.notify_about?(self) }
      else
        notified << assigned_to if assigned_to.active? && assigned_to.notify_about?(self)
      end
    end
    notified.uniq!
    # Remove users that can not view the issue
    notified.select { |user| visible?(user) }
  end

  def done_ratio
    if WorkPackage.use_status_for_done_ratio? && status && status.default_done_ratio
      status.default_done_ratio
    else
      read_attribute(:done_ratio)
    end
  end

  def estimated_hours=(h)
    converted_hours = (h.is_a?(String) ? h.to_hours : h)
    write_attribute :estimated_hours, !!converted_hours ? converted_hours : h
  end

  # >>> issues.rb >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    (project && type) ? (project.all_work_package_custom_fields & type.custom_fields) : []
  end

  def status_id=(sid)
    self.status = nil
    write_attribute(:status_id, sid)
  end

  def priority_id=(pid)
    self.priority = nil
    write_attribute(:priority_id, pid)
  end

  def type_id=(tid)
    self.type = nil
    result = write_attribute(:type_id, tid)
    @custom_field_values = nil
    result
  end

  # Overrides attributes= so that type_id gets assigned first
  def attributes_with_type_first=(new_attributes)
    return if new_attributes.nil?
    new_type_id = new_attributes['type_id'] || new_attributes[:type_id]
    if new_type_id
      self.type_id = new_type_id
    end
    send :attributes_without_type_first=, new_attributes
  end

  # Set the done_ratio using the status if that setting is set.  This will keep the done_ratios
  # even if the user turns off the setting later
  def update_done_ratio_from_status
    if WorkPackage.use_status_for_done_ratio? && status && status.default_done_ratio
      self.done_ratio = status.default_done_ratio
    end
  end

  # Is the amount of work done less than it should for the due date
  def behind_schedule?
    return false if start_date.nil? || due_date.nil?
    done_date = start_date + ((due_date - start_date + 1) * done_ratio / 100).floor
    done_date <= Date.today
  end

  # check if user is allowed to edit WorkPackage Journals.
  # see Redmine::Acts::Journalized::Permissions#journal_editable_by
  def editable_by?(user)
    project = self.project
    allowed = user.allowed_to? :edit_work_package_notes, project,  global: project.present?
    allowed = user.allowed_to? :edit_own_work_package_notes, project,  global: project.present?  unless allowed
    allowed
  end

  # Adds the 'virtual' attribute 'hours' to the result set.  Using the
  # patch in config/initializers/eager_load_with_hours, the value is
  # returned as the #hours attribute on each work package.
  def self.include_spent_hours(user)
    WorkPackage::SpentTime.new(user).scope('time_per_wp')
      .select('time_per_wp.hours')
  end

  # Returns the total number of hours spent on this work package and its descendants.
  # The result can be a subset of the actual spent time in cases where the user's permissions
  # are limited, i.e. he lacks the view_time_entries and/or view_work_packages permission.
  #
  # Example:
  #   spent_hours => 0.0
  #   spent_hours => 50.2
  #
  #   The value can stem from either eager loading the value via
  #   WorkPackage.include_spent_hours in which case the work package has an
  #   #hours attribute or it is loaded on calling the method.
  def spent_hours(user = User.current)
    if respond_to?(:hours)
      hours.to_f
    else
      compute_spent_hours(user)
    end || 0.0
  end

  protected

  def recalculate_attributes_for(work_package_id)
    p = if work_package_id.is_a? WorkPackage
          work_package_id
        else
          WorkPackage.find_by(id: work_package_id)
        end

    return unless p

    p.inherit_priority_from_children

    p.inherit_dates_from_children

    p.inherit_done_ratio_from_leaves

    p.inherit_estimated_hours_from_leaves

    # ancestors will be recursively updated
    if p.changed?
      p.journal_notes =
        I18n.t('work_package.updated_automatically_by_child_changes', child: "##{id}")

      # Ancestors will be updated by parent's after_save hook.
      p.save(validate: false)
    end
  end

  def update_parent_attributes
    recalculate_attributes_for(parent_id) if parent_id.present?
  end

  def inherit_priority_from_children
    # priority = highest priority of children
    if priority_position =
        children.joins(:priority).maximum("#{IssuePriority.table_name}.position")
      self.priority = IssuePriority.find_by(position: priority_position)
    end
  end

  def inherit_dates_from_children
    unless children.empty?
      self.start_date = [children.minimum(:start_date), children.minimum(:due_date)].compact.min
      self.due_date   = [children.maximum(:start_date), children.maximum(:due_date)].compact.max
    end
  end

  def inherit_done_ratio_from_leaves
    return if WorkPackage.done_ratio_disabled?

    # done ratio = weighted average ratio of leaves
    unless WorkPackage.use_status_for_done_ratio? && status && status.default_done_ratio
      leaves_count = leaves.count
      if leaves_count > 0
        average = leaves.average(:estimated_hours).to_f
        if average == 0
          average = 1
        end
        done = leaves.joins(:status).sum("COALESCE(estimated_hours, #{average}) * (CASE WHEN is_closed = #{self.class.connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)").to_f
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
    reload(select: [:lock_version, :created_at, :updated_at])
  end

  # Returns a scope for the projects
  # the user is allowed to move a work package to
  def self.allowed_target_projects_on_move(user)
    Project.where(Project.allowed_to_condition(user, :move_work_packages))
  end

  # Returns a scope for the projects
  # the user is create a work package in
  def self.allowed_target_projects_on_create(user)
    Project.where(Project.allowed_to_condition(user, :add_work_packages))
  end

  # Do not redefine alias chain on reload (see #4838)
  alias_method_chain(:attributes=,
                     :type_first) unless method_defined?(:attributes_without_type_first=)

  def <=>(issue)
    if issue.nil?
      -1
    elsif root_id != issue.root_id
      (root_id || 0) <=> (issue.root_id || 0)
    else
      (lft || 0) <=> (issue.lft || 0)
    end
  end

  # Unassigns issues from +version+ if it's no longer shared with issue's project
  def self.update_versions_from_sharing_change(version)
    # Update issues assigned to the version
    update_versions(["#{WorkPackage.table_name}.fixed_version_id = ?", version.id])
  end

  # Unassigns issues from versions that are no longer shared
  # after +project+ was moved
  def self.update_versions_from_hierarchy_change(project)
    moved_project_ids = project.self_and_descendants.reload.map(&:id)
    # Update issues of the moved projects and issues assigned to a version of a moved project
    update_versions(
      ["#{Version.table_name}.project_id IN (?) OR #{WorkPackage.table_name}.project_id IN (?)",
       moved_project_ids,
       moved_project_ids])
  end

  # Extracted from the ReportsController.
  def self.by_type(project)
    count_and_group_by project: project,
                       field: 'type_id',
                       joins: ::Type.table_name
  end

  def self.by_version(project)
    count_and_group_by project: project,
                       field: 'fixed_version_id',
                       joins: Version.table_name
  end

  def self.by_priority(project)
    count_and_group_by project: project,
                       field: 'priority_id',
                       joins: IssuePriority.table_name
  end

  def self.by_category(project)
    count_and_group_by project: project,
                       field: 'category_id',
                       joins: Category.table_name
  end

  def self.by_assigned_to(project)
    count_and_group_by project: project,
                       field: 'assigned_to_id',
                       joins: User.table_name
  end

  def self.by_responsible(project)
    count_and_group_by project: project,
                       field: 'responsible_id',
                       joins: User.table_name
  end

  def self.by_author(project)
    count_and_group_by project: project,
                       field: 'author_id',
                       joins: User.table_name
  end

  def self.by_subproject(project)
    ActiveRecord::Base.connection.select_all(
      "select    s.id as status_id,
        s.is_closed as closed,
        i.project_id as project_id,
        count(i.id) as total
      from
        #{WorkPackage.table_name} i, #{Status.table_name} s
      where
        i.status_id=s.id
        and i.project_id IN (#{project.descendants.active.map(&:id).join(',')})
      group by s.id, s.is_closed, i.project_id").to_a if project.descendants.active.any?
  end
  # End ReportsController extraction
  # <<< issues.rb <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  private

  def set_default_values
    if new_record? # set default values for new records only
      self.status ||= Status.default
      self.priority ||= IssuePriority.active.default
    end
  end

  def add_time_entry_for(user, attributes)
    return if time_entry_blank?(attributes)

    attributes.reverse_merge!(user: user,
                              spent_on: Date.today)

    time_entries.build(attributes)
  end

  ##
  # Checks if the time entry defined by the given attributes is blank.
  # A time entry counts as blank despite a selected activity if that activity
  # is simply the default activity and all other attributes are blank.
  def time_entry_blank?(attributes)
    return true if attributes.nil?
    key = 'activity_id'
    id = attributes[key]
    default_id = if id && !id.blank?
                   Enumeration.exists? id: id, is_default: true, type: 'TimeEntryActivity'
                 else
                   true
                 end

    default_id && attributes.except(key).values.all?(&:blank?)
  end

  # >>> issues.rb >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  # this removes all attachments separately before destroying the issue
  # avoids getting a ActiveRecord::StaleObjectError when deleting an issue
  def remove_attachments
    # immediately saves to the db
    attachments.clear
    reload # important
  end

  # Update issues so their versions are not pointing to a
  # fixed_version that is not shared with the issue's project
  def self.update_versions(conditions = nil)
    # Only need to update issues with a fixed_version from
    # a different project and that is not systemwide shared
    WorkPackage.where(
      merge_conditions(
        "#{WorkPackage.table_name}.fixed_version_id IS NOT NULL" +
        " AND #{WorkPackage.table_name}.project_id <> #{Version.table_name}.project_id" +
        " AND #{Version.table_name}.sharing <> 'system'",
        conditions))
      .includes(:project, :fixed_version)
      .references(:versions).each do |issue|
      next if issue.project.nil? || issue.fixed_version.nil?
      unless issue.project.shared_versions.include?(issue.fixed_version)
        issue.fixed_version = nil
        issue.save
      end
    end
  end
  private_class_method :update_versions

  # Default assignment based on category
  def default_assign
    if assigned_to.nil? && category && category.assigned_to
      self.assigned_to = category.assigned_to
    end
  end

  # Closes duplicates if the issue is being closed
  def close_duplicates
    if closing?
      duplicates.each do |duplicate|
        # Reload is needed in case the duplicate was updated by a previous duplicate
        duplicate.reload
        # Don't re-close it if it's already closed
        next if duplicate.closed?
        # Implicitly creates a new journal
        duplicate.update_attribute :status, self.status
        # Same user and notes
        duplicate.journals.last.user = current_journal.user
        duplicate.journals.last.notes = current_journal.notes
      end
    end
  end

  # Query generator for selecting groups of issue counts for a project
  # based on specific criteria.
  # DANGER: :field and :joins MUST never come from user input, because
  # they are not SQL-escaped.
  #
  # Options
  # * project - Project to search in.
  # * field - String. Issue field to key off of in the grouping.
  # * joins - String. The table name to join against.
  def self.count_and_group_by(options)
    project = options.delete(:project)
    select_field = options.delete(:field)
    joins = options.delete(:joins)

    where = "i.#{select_field}=j.id"

    ActiveRecord::Base.connection.select_all(
      "select    s.id as status_id,
        s.is_closed as closed,
        j.id as #{select_field},
        count(i.id) as total
      from
          #{WorkPackage.table_name} i, #{Status.table_name} s, #{joins} j
      where
        i.status_id=s.id
        and #{where}
        and i.project_id=#{project.id}
      group by s.id, s.is_closed, j.id").to_a
  end
  private_class_method :count_and_group_by

  # <<< issues.rb <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  def set_attachments_error_details
    if invalid_attachment = attachments.detect { |a| !a.valid? }
      errors.messages[:attachments].first << " - #{invalid_attachment.errors.full_messages.first}"
    end
  end

  def compute_spent_hours(user)
    WorkPackage::SpentTime
      .new(user, self)
      .scope('time_per_wp')
      .where(id: id)
      .pluck('time_per_wp.hours')
      .first
  end
end

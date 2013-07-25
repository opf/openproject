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

class Issue < WorkPackage
  include Redmine::SafeAttributes

  DONE_RATIO_OPTIONS = %w(issue_field issue_status)
  ATTRIBS_WITH_VALUES_FROM_CHILDREN = %w(priority_id start_date due_date estimated_hours done_ratio)

  attr_protected :project_id, :author_id, :lft, :rgt

  validates_presence_of :subject, :priority, :project, :type, :author, :status

  validates_length_of :subject, :maximum => 255
  validates_inclusion_of :done_ratio, :in => 0..100
  validates_numericality_of :estimated_hours, :allow_nil => true

  validate :validate_format_of_due_date
  validate :validate_start_date_before_due_date
  validate :validate_start_date_before_soonest_start_date
  validate :validate_fixed_version_is_assignable
  validate :validate_fixed_version_is_still_open
  validate :validate_enabled_type
  validate :validate_correct_parent

  scope :open, :conditions => ["#{IssueStatus.table_name}.is_closed = ?", false], :include => :status

  scope :with_limit, lambda { |limit| { :limit => limit} }

  scope :on_active_project, lambda { {
    :include => [:status, :project, :type],
    :conditions => "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}" }}

  scope :without_version, lambda {
    {
      :conditions => { :fixed_version_id => nil}
    }
  }

  scope :with_query, lambda {|query|
    {
      :conditions => ::Query.merge_conditions(query.statement)
    }
  }
  #
  # Used for activities list
  def title
    title = ''
    title << subject
    title << ' ('
    title << status.name << ' ' if status
    title << '*'
    title << id.to_s
    title << ')'
  end

  # find all issues
  # * having set a parent_id where the root_id
  #   1) points to self
  #   2) points to an issue with a parent
  #   3) points to an issue having a different root_id
  # * having not set a parent_id but a root_id
  # This unfortunately does not find the issue with the id 3 in the following example
  # | id  | parent_id | root_id |
  # | 1   |           | 1       |
  # | 2   | 1         | 2       |
  # | 3   | 2         | 2       |
  # This would only be possible using recursive statements
  #scope :invalid_root_ids, { :conditions => "(issues.parent_id IS NOT NULL AND " +
  #                                                  "(issues.root_id = issues.id OR " +
  #                                                  "(issues.root_id = parent_issues.id AND parent_issues.parent_id IS NOT NULL) OR " +
  #                                                  "(issues.root_id != parent_issues.root_id))" +
  #                                                ") OR " +
  #                                                "(issues.parent_id IS NULL AND issues.root_id != issues.id)",
  #                                 :joins => "LEFT OUTER JOIN issues parent_issues ON parent_issues.id = issues.parent_id" }

  before_create :default_assign
  before_save :close_duplicates, :update_done_ratio_from_issue_status
  after_save :reschedule_following_issues, :update_nested_set_attributes, :update_parent_attributes
  after_destroy :update_parent_attributes
  before_destroy :remove_attachments

  after_initialize :set_default_values

  def set_default_values
    if new_record? # set default values for new records only
      self.status   ||= IssueStatus.default
      self.priority ||= IssuePriority.default
    end
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    (project && type) ? (project.all_work_package_custom_fields & type.custom_fields.all) : []
  end

  # Moves/copies an issue to a new project and type
  # Returns the moved/copied issue on success, false on failure
  def move_to_project(*args)
    ret = Issue.transaction do
      move_to_project_without_transaction(*args) || raise(ActiveRecord::Rollback)
    end || false
  end

  def move_to_project_without_transaction(new_project, new_type = nil, options = {})
    options ||= {}
    issue = options[:copy] ? self.class.new.copy_from(self) : self

    if new_project && issue.project_id != new_project.id
      delete_relations(issue)
      # issue is moved to another project
      # reassign to the category with same name if any
      new_category = issue.category.nil? ? nil : new_project.issue_categories.find_by_name(issue.category.name)
      issue.category = new_category
      # Keep the fixed_version if it's still valid in the new_project
      unless new_project.shared_versions.include?(issue.fixed_version)
        issue.fixed_version = nil
      end
      issue.project = new_project

      if !Setting.cross_project_issue_relations? &&
         parent && parent.project_id != project_id
        self.parent_issue_id = nil
      end
    end
    if new_type
      issue.type = new_type
      issue.reset_custom_values!
    end
    if options[:copy]
      issue.author = User.current
      issue.custom_field_values = self.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
      issue.status = if options[:attributes] && options[:attributes][:status_id]
                       IssueStatus.find_by_id(options[:attributes][:status_id])
                     else
                       self.status
                     end
    end
    # Allow bulk setting of attributes on the issue
    if options[:attributes]
      issue.attributes = options[:attributes]
    end
    if issue.save
      unless options[:copy]
        # Manually update project_id on related time entries
        TimeEntry.update_all("project_id = #{new_project.id}", {:work_package_id => id})

        issue.children.each do |child|
          unless child.move_to_project_without_transaction(new_project)
            # Move failed and transaction was rollback'd
            return false
          end
        end
      end
    else
      return false
    end
    issue
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
  # Do not redefine alias chain on reload (see #4838)
  alias_method_chain(:attributes=, :type_first) unless method_defined?(:attributes_without_type_first=)

  def estimated_hours=(h)
    converted_hours = (h.is_a?(String) ? h.to_hours : h)
    write_attribute :estimated_hours, !!converted_hours ? converted_hours : h
  end

  safe_attributes 'type_id',
    'status_id',
    'parent_issue_id',
    'category_id',
    'assigned_to_id',
    'priority_id',
    'fixed_version_id',
    'subject',
    'description',
    'start_date',
    'due_date',
    'done_ratio',
    'estimated_hours',
    'custom_field_values',
    'custom_fields',
    'lock_version',
    :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_work_packages, issue.project) }

  safe_attributes 'status_id',
    'assigned_to_id',
    'fixed_version_id',
    'done_ratio',
    :if => lambda {|issue, user| issue.new_statuses_allowed_to(user).any? }

  # Safely sets attributes
  # Should be called from controllers instead of #attributes=
  # attr_accessible is too rough because we still want things like
  # Issue.new(:project => foo) to work
  # TODO: move workflow/permission checks from controllers to here
  def safe_attributes=(attrs, user=User.current)
    return unless attrs.is_a?(Hash)

    # User can change issue attributes only if he has :edit permission or if a workflow transition is allowed
    attrs = delete_unsafe_attributes(attrs, user)
    return if attrs.empty?

    # Type must be set before since new_statuses_allowed_to depends on it.
    if t = attrs.delete('type_id')
      self.type_id = t
    end

    if attrs['status_id']
      unless new_statuses_allowed_to(user).collect(&:id).include?(attrs['status_id'].to_i)
        attrs.delete('status_id')
      end
    end

    if @parent_issue.present?
      attrs.reject! {|k,v| %w(priority_id done_ratio start_date due_date estimated_hours).include?(k)}
    end

    if attrs.has_key?('parent_issue_id')
      if !user.allowed_to?(:manage_subtasks, project)
        attrs.delete('parent_issue_id')
      elsif !attrs['parent_issue_id'].blank?
        attrs.delete('parent_issue_id') unless Issue.visible(user).exists?(attrs['parent_issue_id'].to_i)
      end
    end

    # Bug #501: browsers might swap the line endings causing a Journal.
    if attrs.has_key?('description') && attrs['description'].present?
      if attrs['description'].gsub(/\r\n?/,"\n") == self.description
        attrs.delete('description')
      end
    end

    self.attributes = attrs
  end

  def done_ratio
    if Issue.use_status_for_done_ratio? && status && status.default_done_ratio
      status.default_done_ratio
    else
      read_attribute(:done_ratio)
    end
  end

  def self.use_field_for_done_ratio?
    Setting.issue_done_ratio == 'issue_field'
  end

  def validate_format_of_due_date
    if self.due_date.nil? && @attributes['due_date'] && !@attributes['due_date'].empty?
      errors.add :due_date, :not_a_date
    end
  end

  def validate_start_date_before_due_date
    if self.due_date and self.start_date and self.due_date < self.start_date
      errors.add :due_date, :greater_than_start_date
    end
  end

  def validate_start_date_before_soonest_start_date
    if start_date && soonest_start && start_date < soonest_start
      errors.add :start_date, :invalid
    end
  end

  def validate_fixed_version_is_assignable
    if fixed_version
      errors.add :fixed_version_id, :inclusion unless assignable_versions.include?(fixed_version)
    end
  end

  def validate_fixed_version_is_still_open
    if fixed_version && assignable_versions.include?(fixed_version)
      errors.add :base, I18n.t(:error_can_not_reopen_issue_on_closed_version) if reopened? && fixed_version.closed?
    end
  end

  def validate_enabled_type
    # Checks that the issue can not be added/moved to a disabled type
    if project && (type_id_changed? || project_id_changed?)
      errors.add :type_id, :inclusion unless project.types.include?(type)
    end
  end

  def validate_correct_parent
    # Checks parent issue assignment
    if @parent_issue
      if !Setting.cross_project_issue_relations? && @parent_issue.project_id != self.project_id
        errors.add :parent_issue_id, :not_a_valid_parent
      elsif !new_record?
        # moving an existing issue
        if @parent_issue.root_id != root_id
          # we can always move to another tree
        elsif move_possible?(@parent_issue)
          # move accepted inside tree
        else
          errors.add :parent_issue_id, :not_a_valid_parent
        end
      end
    end
  end

  # Set the done_ratio using the status if that setting is set.  This will keep the done_ratios
  # even if the user turns off the setting later
  def update_done_ratio_from_issue_status
    if Issue.use_status_for_done_ratio? && status && status.default_done_ratio
      self.done_ratio = status.default_done_ratio
    end
  end

  # Return true if the issue is being reopened
  def reopened?
    if !new_record? && status_id_changed?
      status_was = IssueStatus.find_by_id(status_id_was)
      status_new = IssueStatus.find_by_id(status_id)
      if status_was && status_new && status_was.is_closed? && !status_new.is_closed?
        return true
      end
    end
    false
  end

  # Return true if the issue is being closed
  def closing?
    if !new_record? && status_id_changed?
      status_was = IssueStatus.find_by_id(status_id_was)
      status_new = IssueStatus.find_by_id(status_id)
      if status_was && status_new && !status_was.is_closed? && status_new.is_closed?
        return true
      end
    end
    false
  end

  # Is the amount of work done less than it should for the due date
  def behind_schedule?
    return false if start_date.nil? || due_date.nil?
    done_date = start_date + ((due_date - start_date+1)* done_ratio/100).floor
    return done_date <= Date.today
  end

  # Does this issue have children?
  def children?
    !leaf?
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

  # Returns the mail adresses of users that should be notified
  def recipients
    notified = project.notified_users
    # Author and assignee are always notified unless they have been
    # locked or don't want to be notified
    notified << author if author && author.active? && author.notify_about?(self)
    notified << assigned_to if assigned_to && assigned_to.active? && assigned_to.notify_about?(self)
    notified.uniq!
    # Remove users that can not view the issue
    notified.reject! {|user| !visible?(user)}
    notified.collect(&:mail)
  end

  # Returns the total number of hours spent on this issue and its descendants
  #
  # Example:
  #   spent_hours => 0.0
  #   spent_hours => 50.2
  def spent_hours
    @spent_hours ||= self_and_descendants.joins(:time_entries).sum("#{TimeEntry.table_name}.hours").to_f || 0.0
  end

  # Returns the time scheduled for this issue.
  #
  # Example:
  #   Start Date: 2/26/09, End Date: 3/04/09
  #   duration => 6
  def duration
    (start_date && due_date) ? due_date - start_date : 0
  end

  def reschedule_after(date)
    return if date.nil?
    if leaf?
      if start_date.nil? || start_date < date
        self.start_date, self.due_date = date, date + duration
        save
      end
    else
      leaves.each do |leaf|
        leaf.reschedule_after(date)
      end
    end
  end

  def <=>(issue)
    if issue.nil?
      -1
    elsif root_id != issue.root_id
      (root_id || 0) <=> (issue.root_id || 0)
    else
      (lft || 0) <=> (issue.lft || 0)
    end
  end

  # The number of "items" this issue spans in it's nested set
  #
  # A parent issue would span all of it's children + 1 left + 1 right (3)
  #
  #   |  parent |
  #   || child ||
  #
  # A child would span only itself (1)
  #
  #   |child|
  def nested_set_span
    rgt - lft
  end

  # TODO: remove. This is left here to avoid regression
  # but the code was duplicated to work_packages_helper
  # and thus should be removed as soon as possible.
  # Returns a string of css classes that apply to the issue
  def css_classes
    s = "issue status-#{status.position} priority-#{priority.position}"
    s << ' closed' if closed?
    s << ' overdue' if overdue?
    s << ' child' if child?
    s << ' parent' unless leaf?
    s << ' created-by-me' if User.current.logged? && author_id == User.current.id
    s << ' assigned-to-me' if User.current.logged? && assigned_to_id == User.current.id
    s
  end

  # Saves an issue, time_entry, attachments, and a journal from the parameters
  # Returns false if save fails
  def save_issue_with_child_records(params, existing_time_entry=nil)
    Issue.transaction do
      if params[:time_entry] && (params[:time_entry][:hours].present? || params[:time_entry][:comments].present?) && User.current.allowed_to?(:log_time, project)
        @time_entry = existing_time_entry || TimeEntry.new
        @time_entry.project = project
        @time_entry.work_package = self
        @time_entry.user = User.current
        @time_entry.spent_on = Date.today
        @time_entry.attributes = params[:time_entry]
        self.time_entries << @time_entry
      end

      if valid?
        attachments = Attachment.attach_files(self, params[:attachments])

        # TODO: Rename hook
        Redmine::Hook.call_hook(:controller_issues_edit_before_save, { :params => params, :issue => self, :time_entry => @time_entry, :journal => current_journal})
        begin
          if save
            # TODO: Rename hook
            Redmine::Hook.call_hook(:controller_issues_edit_after_save, { :params => params, :issue => self, :time_entry => @time_entry, :journal => current_journal})
          else
            raise ActiveRecord::Rollback
          end
        rescue ActiveRecord::StaleObjectError
          attachments[:files].each(&:destroy)
          error_message = l(:notice_locking_conflict)

          journals_since = self.journals.after(lock_version)

          if journals_since.any?
            changes = journals_since.map { |j| "#{j.user.name} (#{j.created_at.to_s(:short)})" }
            error_message << " " << l(:notice_locking_conflict_additional_information, :users => changes.join(', '))
          end

          error_message << " " << l(:notice_locking_conflict_reload_page)

          errors.add :base, error_message
          raise ActiveRecord::Rollback
        end
      end
    end
  end

  # Unassigns issues from +version+ if it's no longer shared with issue's project
  def self.update_versions_from_sharing_change(version)
    # Update issues assigned to the version
    update_versions(["#{Issue.table_name}.fixed_version_id = ?", version.id])
  end

  # Unassigns issues from versions that are no longer shared
  # after +project+ was moved
  def self.update_versions_from_hierarchy_change(project)
    moved_project_ids = project.self_and_descendants.reload.collect(&:id)
    # Update issues of the moved projects and issues assigned to a version of a moved project
    Issue.update_versions(["#{Version.table_name}.project_id IN (?) OR #{Issue.table_name}.project_id IN (?)", moved_project_ids, moved_project_ids])
  end

  def parent_issue_id=(arg)
    parent_issue_id = arg.blank? ? nil : arg.to_i
    if parent_issue_id && @parent_issue = Issue.find_by_id(parent_issue_id)
      journal_changes["parent_id"] = [self.parent_id, @parent_issue.id]
      @parent_issue.id
    else
      @parent_issue = nil
      journal_changes["parent_id"] = [self.parent_id, nil]
      nil
    end
  end

  def parent_issue_id
    if instance_variable_defined? :@parent_issue
      @parent_issue.nil? ? nil : @parent_issue.id
    else
      parent_id
    end
  end

  # Extracted from the ReportsController.
  def self.by_type(project)
    count_and_group_by(:project => project,
                       :field => 'type_id',
                       :joins => Type.table_name)
  end

  def self.by_version(project)
    count_and_group_by(:project => project,
                       :field => 'fixed_version_id',
                       :joins => Version.table_name)
  end

  def self.by_priority(project)
    count_and_group_by(:project => project,
                       :field => 'priority_id',
                       :joins => IssuePriority.table_name)
  end

  def self.by_category(project)
    count_and_group_by(:project => project,
                       :field => 'category_id',
                       :joins => IssueCategory.table_name)
  end

  def self.by_assigned_to(project)
    count_and_group_by(:project => project,
                       :field => 'assigned_to_id',
                       :joins => User.table_name)
  end

  def self.by_author(project)
    count_and_group_by(:project => project,
                       :field => 'author_id',
                       :joins => User.table_name)
  end

  def self.by_subproject(project)
    ActiveRecord::Base.connection.select_all("select    s.id as status_id,
                                                s.is_closed as closed,
                                                i.project_id as project_id,
                                                count(i.id) as total
                                              from
                                                #{Issue.table_name} i, #{IssueStatus.table_name} s
                                              where
                                                i.status_id=s.id
                                                and i.project_id IN (#{project.descendants.active.collect{|p| p.id}.join(',')})
                                              group by s.id, s.is_closed, i.project_id") if project.descendants.active.any?
  end
  # End ReportsController extraction

  # Returns an array of projects that current user can move issues to
  def self.allowed_target_projects_on_move
    projects = []
    if User.current.admin?
      # admin is allowed to move issues to any active (visible) project
      projects = Project.visible.all
    elsif User.current.logged?
      if Role.non_member.allowed_to?(:move_issues)
        projects = Project.visible.all
      else
        User.current.memberships.each {|m| projects << m.project if m.roles.detect {|r| r.allowed_to?(:move_issues)}}
      end
    end
    projects
  end

  # method from acts_as_nested_set
  def self.valid?
    super && invalid_root_ids.empty?
  end

  def self.all_invalid
    (super + invalid_root_ids).uniq
  end

  def self.rebuild_silently!(roots = nil)

    invalid_root_ids_to_fix = if roots.is_a? Array
                                roots
                              elsif roots.present?
                                [roots]
                              else
                                []
                              end

    known_issue_parents = Hash.new do |hash, ancestor_id|
      hash[ancestor_id] = Issue.find_by_id(ancestor_id)
    end

    fix_known_invalid_root_ids = lambda do
      issues = invalid_root_ids

      issues_roots = []

      issues.each do |issue|
        # At this point we can not trust nested set methods as the root_id is invalid.
        # Therefore we trust the parent_issue_id to fetch all ancestors until we find the root
        ancestor = issue

        while ancestor.parent_issue_id do
          ancestor = known_issue_parents[ancestor.parent_issue_id]
        end

        issues_roots << ancestor

        if invalid_root_ids_to_fix.empty? || invalid_root_ids_to_fix.map(&:id).include?(ancestor.id)
          Issue.update_all({ :root_id => ancestor.id },
                           { :id => issue.id })
        end
      end

      fix_known_invalid_root_ids.call unless (issues_roots.map(&:id) & invalid_root_ids_to_fix.map(&:id)).empty?
    end

    fix_known_invalid_root_ids.call

    super
  end

  private

  def update_nested_set_attributes
    if root_id.nil?
      # issue was just created
      self.root_id = (@parent_issue.nil? ? id : @parent_issue.root_id)
      set_default_left_and_right
      Issue.update_all("root_id = #{root_id}, lft = #{lft}, rgt = #{rgt}", ["id = ?", id])
      if @parent_issue
        move_to_child_of(@parent_issue)
      end
      reload
    elsif parent_issue_id != parent_id
      former_parent_id = parent_id
      # moving an existing issue
      if @parent_issue && @parent_issue.root_id == root_id
        # inside the same tree
        move_to_child_of(@parent_issue)
      else
        # to another tree
        unless root?
          move_to_right_of(root)
          reload
        end
        old_root_id = root_id
        self.root_id = (@parent_issue.nil? ? id : @parent_issue.root_id )
        target_maxright = nested_set_scope.maximum(right_column_name) || 0
        offset = target_maxright + 1 - lft
        Issue.update_all("root_id = #{root_id}, lft = lft + #{offset}, rgt = rgt + #{offset}",
                          ["root_id = ? AND lft >= ? AND rgt <= ? ", old_root_id, lft, rgt])
        self[left_column_name] = lft + offset
        self[right_column_name] = rgt + offset
        if @parent_issue
          move_to_child_of(@parent_issue)
        end
      end
      reload

      # delete invalid relations of all descendants
      self_and_descendants.each do |issue|
        issue.relations.each do |relation|
          relation.destroy unless relation.valid?
        end
      end

      # update former parent
      recalculate_attributes_for(former_parent_id) if former_parent_id
    end
    remove_instance_variable(:@parent_issue) if instance_variable_defined?(:@parent_issue)
  end

  # this removes all attachments separately before destroying the issue
  # avoids getting a ActiveRecord::StaleObjectError when deleting an issue
  def remove_attachments
    # immediately saves to the db
    attachments.clear
    reload # important
  end

  def update_parent_attributes
    recalculate_attributes_for(parent_id) if parent_id
  end

  # Update issues so their versions are not pointing to a
  # fixed_version that is not shared with the issue's project
  def self.update_versions(conditions=nil)
    # Only need to update issues with a fixed_version from
    # a different project and that is not systemwide shared
    Issue.all(:conditions => merge_conditions("#{Issue.table_name}.fixed_version_id IS NOT NULL" +
                                                " AND #{Issue.table_name}.project_id <> #{Version.table_name}.project_id" +
                                                " AND #{Version.table_name}.sharing <> 'system'",
                                                conditions),
              :include => [:project, :fixed_version]
              ).each do |issue|
      next if issue.project.nil? || issue.fixed_version.nil?
      unless issue.project.shared_versions.include?(issue.fixed_version)
        issue.fixed_version = nil
        issue.save
      end
    end
  end

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
        # Reload is need in case the duplicate was updated by a previous duplicate
        duplicate.reload
        # Don't re-close it if it's already closed
        next if duplicate.closed?
        # Implicitely creates a new journal
        duplicate.update_attribute :status, self.status
        # Same user and notes
        duplicate.journals.last.user = current_journal.user
        duplicate.journals.last.notes = current_journal.notes
      end
    end
  end

  # Query generator for selecting groups of issue counts for a project
  # based on specific criteria
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

    ActiveRecord::Base.connection.select_all("select    s.id as status_id,
                                                s.is_closed as closed,
                                                j.id as #{select_field},
                                                count(i.id) as total
                                              from
                                                  #{Issue.table_name} i, #{IssueStatus.table_name} s, #{joins} j
                                              where
                                                i.status_id=s.id
                                                and #{where}
                                                and i.project_id=#{project.id}
                                              group by s.id, s.is_closed, j.id")
  end
end

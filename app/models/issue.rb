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

  before_create :default_assign
  before_save :close_duplicates, :update_done_ratio_from_issue_status
  before_destroy :remove_attachments

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    (project && type) ? (project.all_work_package_custom_fields & type.custom_fields.all) : []
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
    'parent_id',
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

    if parent.present?
      attrs.reject! {|k,v| %w(priority_id done_ratio start_date due_date estimated_hours).include?(k)}
    end

    if attrs.has_key?('parent_id')
      if !user.allowed_to?(:manage_subtasks, project)
        attrs.delete('parent_id')
      elsif !attrs['parent_id'].blank?
        attrs.delete('parent_id') unless WorkPackage.visible(user).exists?(attrs['parent_id'].to_i)
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
      errors.add :base, I18n.t(:error_can_not_reopen_work_package_on_closed_version) if reopened? && fixed_version.closed?
    end
  end

  def validate_enabled_type
    # Checks that the issue can not be added/moved to a disabled type
    if project && (type_id_changed? || project_id_changed?)
      errors.add :type_id, :inclusion unless project.types.include?(type)
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

  def <=>(issue)
    if issue.nil?
      -1
    elsif root_id != issue.root_id
      (root_id || 0) <=> (issue.root_id || 0)
    else
      (lft || 0) <=> (issue.lft || 0)
    end
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

  private

  # this removes all attachments separately before destroying the issue
  # avoids getting a ActiveRecord::StaleObjectError when deleting an issue
  def remove_attachments
    # immediately saves to the db
    attachments.clear
    reload # important
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

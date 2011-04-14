# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class Issue < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  belongs_to :project
  belongs_to :tracker
  belongs_to :status, :class_name => 'IssueStatus', :foreign_key => 'status_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :fixed_version, :class_name => 'Version', :foreign_key => 'fixed_version_id'
  belongs_to :priority, :class_name => 'IssuePriority', :foreign_key => 'priority_id'
  belongs_to :category, :class_name => 'IssueCategory', :foreign_key => 'category_id'

  has_many :time_entries, :dependent => :delete_all
  has_and_belongs_to_many :changesets, :order => "#{Changeset.table_name}.committed_on ASC, #{Changeset.table_name}.id ASC"
  
  has_many :relations_from, :class_name => 'IssueRelation', :foreign_key => 'issue_from_id', :dependent => :delete_all
  has_many :relations_to, :class_name => 'IssueRelation', :foreign_key => 'issue_to_id', :dependent => :delete_all
  
  acts_as_nested_set :scope => 'root_id', :dependent => :destroy
  acts_as_attachable :after_remove => :attachment_removed
  acts_as_customizable
  acts_as_watchable

  acts_as_journalized :event_title => Proc.new {|o| "#{o.tracker.name} ##{o.journaled_id} (#{o.status}): #{o.subject}"},
                      :event_type => Proc.new {|o| 'issue' + (o.closed? ? ' closed' : '') },
                      :except => [:description]

  register_on_journal_formatter(:id, 'parent_id')
  register_on_journal_formatter(:named_association, 'project_id', 'status_id', 'tracker_id', 'assigned_to_id',
      'priority_id', 'category_id', 'fixed_version_id')
  register_on_journal_formatter(:fraction, 'estimated_hours')
  register_on_journal_formatter(:decimal, 'done_ratio')
  register_on_journal_formatter(:datetime, 'due_date', 'start_date')
  register_on_journal_formatter(:plaintext, 'subject')

  acts_as_searchable :columns => ['subject', "#{table_name}.description", "#{Journal.table_name}.notes"],
                     :include => [:project, :journals],
                     # sort by id so that limited eager loading doesn't break with postgresql
                     :order_column => "#{table_name}.id"

  DONE_RATIO_OPTIONS = %w(issue_field issue_status)

  validates_presence_of :subject, :priority, :project, :tracker, :author, :status

  validates_length_of :subject, :maximum => 255
  validates_inclusion_of :done_ratio, :in => 0..100
  validates_numericality_of :estimated_hours, :allow_nil => true

  named_scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_issues) } }
  
  named_scope :open, :conditions => ["#{IssueStatus.table_name}.is_closed = ?", false], :include => :status

  named_scope :recently_updated, :order => "#{Issue.table_name}.updated_on DESC"
  named_scope :with_limit, lambda { |limit| { :limit => limit} }
  named_scope :on_active_project, :include => [:status, :project, :tracker],
                                  :conditions => ["#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"]
  named_scope :for_gantt, lambda {
    {
      :include => [:tracker, :status, :assigned_to, :priority, :project, :fixed_version]
    }
  }

  named_scope :without_version, lambda {
    {
      :conditions => { :fixed_version_id => nil}
    }
  }

  named_scope :with_query, lambda {|query|
    {
      :conditions => Query.merge_conditions(query.statement)
    }
  }

  before_create :default_assign
  before_save :close_duplicates, :update_done_ratio_from_issue_status
  after_save :reschedule_following_issues, :update_nested_set_attributes, :update_parent_attributes
  after_destroy :update_parent_attributes
  
  # Returns true if usr or current user is allowed to view the issue
  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_issues, self.project)
  end
  
  def after_initialize
    if new_record?
      # set default values for new records only
      self.status ||= IssueStatus.default
      self.priority ||= IssuePriority.default
    end
  end
  
  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    (project && tracker) ? project.all_issue_custom_fields.select {|c| tracker.custom_fields.include? c } : []
  end
  
  def copy_from(arg)
    issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
    self.attributes = issue.attributes.dup.except("id", "root_id", "parent_id", "lft", "rgt", "created_on", "updated_on")
    self.custom_field_values = issue.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
    self.status = issue.status
    self
  end
  
  # Moves/copies an issue to a new project and tracker
  # Returns the moved/copied issue on success, false on failure
  def move_to_project(*args)
    ret = Issue.transaction do
      move_to_project_without_transaction(*args) || raise(ActiveRecord::Rollback)
    end || false
  end
  
  def move_to_project_without_transaction(new_project, new_tracker = nil, options = {})
    options ||= {}
    issue = options[:copy] ? self.class.new.copy_from(self) : self
    
    if new_project && issue.project_id != new_project.id
      # delete issue relations
      unless Setting.cross_project_issue_relations?
        issue.relations_from.clear
        issue.relations_to.clear
      end
      # issue is moved to another project
      # reassign to the category with same name if any
      new_category = issue.category.nil? ? nil : new_project.issue_categories.find_by_name(issue.category.name)
      issue.category = new_category
      # Keep the fixed_version if it's still valid in the new_project
      unless new_project.shared_versions.include?(issue.fixed_version)
        issue.fixed_version = nil
      end
      issue.project = new_project
      if issue.parent && issue.parent.project_id != issue.project_id
        issue.parent_issue_id = nil
      end
    end
    if new_tracker
      issue.tracker = new_tracker
      issue.reset_custom_values!
    end
    if options[:copy]
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
        TimeEntry.update_all("project_id = #{new_project.id}", {:issue_id => id})
        
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

  def tracker_id=(tid)
    self.tracker = nil
    result = write_attribute(:tracker_id, tid)
    @custom_field_values = nil
    result
  end
  
  # Overrides attributes= so that tracker_id gets assigned first
  def attributes_with_tracker_first=(new_attributes, *args)
    return if new_attributes.nil?
    new_tracker_id = new_attributes['tracker_id'] || new_attributes[:tracker_id]
    if new_tracker_id
      self.tracker_id = new_tracker_id
    end
    send :attributes_without_tracker_first=, new_attributes, *args
  end
  # Do not redefine alias chain on reload (see #4838)
  alias_method_chain(:attributes=, :tracker_first) unless method_defined?(:attributes_without_tracker_first=)
  
  def estimated_hours=(h)
    write_attribute :estimated_hours, (h.is_a?(String) ? h.to_hours : h)
  end
  
  safe_attributes 'tracker_id',
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
    :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }
  
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
    
    # Tracker must be set before since new_statuses_allowed_to depends on it.
    if t = attrs.delete('tracker_id')
      self.tracker_id = t
    end
    
    if attrs['status_id']
      unless new_statuses_allowed_to(user).collect(&:id).include?(attrs['status_id'].to_i)
        attrs.delete('status_id')
      end
    end
    
    unless leaf?
      attrs.reject! {|k,v| %w(priority_id done_ratio start_date due_date estimated_hours).include?(k)}
    end
    
    if attrs.has_key?('parent_issue_id')
      if !user.allowed_to?(:manage_subtasks, project)
        attrs.delete('parent_issue_id')
      elsif !attrs['parent_issue_id'].blank?
        attrs.delete('parent_issue_id') unless Issue.visible(user).exists?(attrs['parent_issue_id'].to_i)
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

  def self.use_status_for_done_ratio?
    Setting.issue_done_ratio == 'issue_status'
  end

  def self.use_field_for_done_ratio?
    Setting.issue_done_ratio == 'issue_field'
  end
  
  def validate
    if self.due_date.nil? && @attributes['due_date'] && !@attributes['due_date'].empty?
      errors.add :due_date, :not_a_date
    end
    
    if self.due_date and self.start_date and self.due_date < self.start_date
      errors.add :due_date, :greater_than_start_date
    end
    
    if start_date && soonest_start && start_date < soonest_start
      errors.add :start_date, :invalid
    end
    
    if fixed_version
      if !assignable_versions.include?(fixed_version)
        errors.add :fixed_version_id, :inclusion
      elsif reopened? && fixed_version.closed?
        errors.add_to_base I18n.t(:error_can_not_reopen_issue_on_closed_version)
      end
    end
    
    # Checks that the issue can not be added/moved to a disabled tracker
    if project && (tracker_id_changed? || project_id_changed?)
      unless project.trackers.include?(tracker)
        errors.add :tracker_id, :inclusion
      end
    end
    
    # Checks parent issue assignment
    if @parent_issue
      if @parent_issue.project_id != project_id
        errors.add :parent_issue_id, :not_same_project
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
  
  # Callback on attachment deletion
  def attachment_removed(obj)
    init_journal(User.current)
    create_journal
    last_journal.update_attribute(:changes, {obj.id => [obj.filename, nil]}.to_yaml)
  end
  
  # Return true if the issue is closed, otherwise false
  def closed?
    self.status.is_closed?
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
  
  # Returns true if the issue is overdue
  def overdue?
    !due_date.nil? && (due_date < Date.today) && !status.is_closed?
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
  
  # Users the issue can be assigned to
  def assignable_users
    users = project.assignable_users
    users << author if author
    users.uniq.sort
  end
  
  # Versions that the issue can be assigned to
  def assignable_versions
    @assignable_versions ||= (project.shared_versions.open + [Version.find_by_id(fixed_version_id_was)]).compact.uniq.sort
  end
  
  # Returns true if this issue is blocked by another issue that is still open
  def blocked?
    !relations_to.detect {|ir| ir.relation_type == 'blocks' && !ir.issue_from.closed?}.nil?
  end
  
  # Returns an array of status that user is able to apply
  def new_statuses_allowed_to(user, include_default=false)
    statuses = status.find_new_statuses_allowed_to(user.roles_for_project(project), tracker)
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
    @spent_hours ||= self_and_descendants.sum("#{TimeEntry.table_name}.hours", :include => :time_entries).to_f || 0.0
  end
  
  def relations
    (relations_from + relations_to).sort
  end
  
  def all_dependent_issues(except=nil)
    except ||= self
    dependencies = []
    relations_from.each do |relation|
      if relation.issue_to && relation.issue_to != except
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
  
  # Returns the due date or the target due date if any
  # Used on gantt chart
  def due_before
    due_date || (fixed_version ? fixed_version.effective_date : nil)
  end
  
  # Returns the time scheduled for this issue.
  # 
  # Example:
  #   Start Date: 2/26/09, End Date: 3/04/09
  #   duration => 6
  def duration
    (start_date && due_date) ? due_date - start_date : 0
  end
  
  def soonest_start
    @soonest_start ||= (
        relations_to.collect{|relation| relation.successor_soonest_start} +
        ancestors.collect(&:soonest_start)
      ).compact.max
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
  
  def to_s
    "#{tracker} ##{id}: #{subject}"
  end
  
  # Returns a string of css classes that apply to the issue
  def css_classes
    s = "issue status-#{status.position} priority-#{priority.position}"
    s << ' closed' if closed?
    s << ' overdue' if overdue?
    s << ' created-by-me' if User.current.logged? && author_id == User.current.id
    s << ' assigned-to-me' if User.current.logged? && assigned_to_id == User.current.id
    s
  end

  # Saves an issue, time_entry, attachments, and a journal from the parameters
  # Returns false if save fails
  def save_issue_with_child_records(params, existing_time_entry=nil)
    Issue.transaction do
      if params[:time_entry] && params[:time_entry][:hours].present? && User.current.allowed_to?(:log_time, project)
        @time_entry = existing_time_entry || TimeEntry.new
        @time_entry.project = project
        @time_entry.issue = self
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
          errors.add_to_base l(:notice_locking_conflict)
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
      @parent_issue.id
    else
      @parent_issue = nil
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
  def self.by_tracker(project)
    count_and_group_by(:project => project,
                       :field => 'tracker_id',
                       :joins => Tracker.table_name)
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
  
  def update_parent_attributes
    recalculate_attributes_for(parent_id) if parent_id
  end

  def recalculate_attributes_for(issue_id)
    if issue_id && p = Issue.find_by_id(issue_id)
      # priority = highest priority of children
      if priority_position = p.children.maximum("#{IssuePriority.table_name}.position", :include => :priority)
        p.priority = IssuePriority.find_by_position(priority_position)
      end
      
      # start/due dates = lowest/highest dates of children
      p.start_date = p.children.minimum(:start_date)
      p.due_date = p.children.maximum(:due_date)
      if p.start_date && p.due_date && p.due_date < p.start_date
        p.start_date, p.due_date = p.due_date, p.start_date
      end
      
      # done ratio = weighted average ratio of leaves
      unless Issue.use_status_for_done_ratio? && p.status && p.status.default_done_ratio
        leaves_count = p.leaves.count
        if leaves_count > 0
          average = p.leaves.average(:estimated_hours).to_f
          if average == 0
            average = 1
          end
          done = p.leaves.sum("COALESCE(estimated_hours, #{average}) * (CASE WHEN is_closed = #{connection.quoted_true} THEN 100 ELSE COALESCE(done_ratio, 0) END)", :include => :status).to_f
          progress = done / (average * leaves_count)
          p.done_ratio = progress.round
        end
      end
      
      # estimate = sum of leaves estimates
      p.estimated_hours = p.leaves.sum(:estimated_hours).to_f
      p.estimated_hours = nil if p.estimated_hours == 0.0
      
      # ancestors will be recursively updated
      p.save(false)
    end
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

  # Updates start/due dates of following issues
  def reschedule_following_issues
    if start_date_changed? || due_date_changed?
      relations_from.each do |relation|
        relation.set_issue_to_dates
      end
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
  

  IssueJournal.class_eval do
    # Shortcut
    def new_status
      if details.keys.include? 'status_id'
        (newval = details['status_id'].last) ? IssueStatus.find_by_id(newval.to_i) : nil
      end
    end
  end

end

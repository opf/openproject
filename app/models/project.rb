#-- encoding: UTF-8
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

class Project < ActiveRecord::Base
  include Redmine::SafeAttributes

  # Project statuses
  STATUS_ACTIVE     = 1
  STATUS_ARCHIVED   = 9

  # Maximum length for project identifiers
  IDENTIFIER_MAX_LENGTH = 100

  # Specific overidden Activities
  has_many :time_entry_activities
  has_many :members, :include => [:user, :roles], :conditions => "#{User.table_name}.type='User' AND #{User.table_name}.status=#{User::STATUS_ACTIVE}"
  has_many :memberships, :class_name => 'Member'
  has_many :member_principals, :class_name => 'Member',
                               :include => :principal,
                               :conditions => "#{Principal.table_name}.type='Group' OR (#{Principal.table_name}.type='User' AND #{Principal.table_name}.status=#{User::STATUS_ACTIVE})"
  has_many :users, :through => :members
  has_many :principals, :through => :member_principals, :source => :principal

  has_many :enabled_modules, :dependent => :delete_all
  has_and_belongs_to_many :trackers, :order => "#{Tracker.table_name}.position"
  has_many :issues, :dependent => :destroy, :order => "#{Issue.table_name}.created_on DESC", :include => [:status, :tracker]
  has_many :issue_changes, :through => :issues, :source => :journals
  has_many :versions, :dependent => :destroy, :order => "#{Version.table_name}.effective_date DESC, #{Version.table_name}.name DESC"
  has_many :time_entries, :dependent => :delete_all
  has_many :queries, :dependent => :delete_all
  has_many :documents, :dependent => :destroy
  has_many :news, :dependent => :destroy, :include => :author
  has_many :issue_categories, :dependent => :delete_all, :order => "#{IssueCategory.table_name}.name"
  has_many :boards, :dependent => :destroy, :order => "position ASC"
  has_one :repository, :dependent => :destroy
  has_many :changesets, :through => :repository
  has_one :wiki, :dependent => :destroy
  # Custom field for the project issues
  has_and_belongs_to_many :issue_custom_fields,
                          :class_name => 'IssueCustomField',
                          :order => "#{CustomField.table_name}.position",
                          :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
                          :association_foreign_key => 'custom_field_id'

  acts_as_nested_set :order => 'name', :dependent => :destroy
  acts_as_attachable :view_permission => :view_files,
                     :delete_permission => :manage_files

  acts_as_customizable
  acts_as_searchable :columns => ['name', 'identifier', 'description'], :project_key => 'id', :permission => nil
  acts_as_event :title => Proc.new {|o| "#{l(:label_project)}: #{o.name}"},
                :url => Proc.new {|o| {:controller => 'projects', :action => 'show', :id => o}},
                :author => nil

  attr_protected :status

  validates_presence_of :name, :identifier
  validates_uniqueness_of :identifier
  validates_associated :repository, :wiki
  validates_length_of :name, :maximum => 255
  validates_length_of :homepage, :maximum => 255
  validates_length_of :identifier, :in => 1..IDENTIFIER_MAX_LENGTH
  # donwcase letters, digits, dashes but not digits only
  validates_format_of :identifier, :with => /^(?!\d+$)[a-z0-9\-_]*$/, :if => Proc.new { |p| p.identifier_changed? }
  # reserved words
  validates_exclusion_of :identifier, :in => %w( new )

  before_destroy :delete_all_members

  named_scope :has_module, lambda { |mod| { :conditions => ["#{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name=?)", mod.to_s] } }
  named_scope :active, { :conditions => "#{Project.table_name}.status = #{STATUS_ACTIVE}"}
  named_scope :all_public, { :conditions => { :is_public => true } }
  named_scope :visible, lambda { { :conditions => Project.visible_by(User.current) } }

  def initialize(attributes = nil)
    super

    initialized = (attributes || {}).stringify_keys
    if !initialized.key?('identifier') && Setting.sequential_project_identifiers?
      self.identifier = Project.next_identifier
    end
    if !initialized.key?('is_public')
      self.is_public = Setting.default_projects_public?
    end
    if !initialized.key?('enabled_module_names')
      self.enabled_module_names = Setting.default_projects_modules
    end
    if !initialized.key?('trackers') && !initialized.key?('tracker_ids')
      self.trackers = Tracker.all
    end
  end

  def identifier=(identifier)
    super unless identifier_frozen?
  end

  def identifier_frozen?
    errors[:identifier].nil? && !(new_record? || identifier.blank?)
  end

  # returns latest created projects
  # non public projects will be returned only if user is a member of those
  def self.latest(user=nil, count=5)
    find(:all, :limit => count, :conditions => visible_by(user), :order => "created_on DESC")
  end

  # Returns a SQL :conditions string used to find all active projects for the specified user.
  #
  # Examples:
  #     Projects.visible_by(admin)        => "projects.status = 1"
  #     Projects.visible_by(normal_user)  => "projects.status = 1 AND projects.is_public = 1"
  def self.visible_by(user=nil)
    user ||= User.current
    if user && user.admin?
      return "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
    elsif user && user.memberships.any?
      return "#{Project.table_name}.status=#{Project::STATUS_ACTIVE} AND (#{Project.table_name}.is_public = #{connection.quoted_true} or #{Project.table_name}.id IN (#{user.memberships.collect{|m| m.project_id}.join(',')}))"
    else
      return "#{Project.table_name}.status=#{Project::STATUS_ACTIVE} AND #{Project.table_name}.is_public = #{connection.quoted_true}"
    end
  end

  def self.allowed_to_condition(user, permission, options={})
    base_statement = "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
    if perm = Redmine::AccessControl.permission(permission)
      unless perm.project_module.nil?
        # If the permission belongs to a project module, make sure the module is enabled
        base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
      end
    end
    if options[:project]
      project_statement = "#{Project.table_name}.id = #{options[:project].id}"
      project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
      base_statement = "(#{project_statement}) AND (#{base_statement})"
    end

    if user.admin?
      base_statement
    else
      statement_by_role = {}
      if user.logged?
        if Role.non_member.allowed_to?(permission) && !options[:member]
          statement_by_role[Role.non_member] = "#{Project.table_name}.is_public = #{connection.quoted_true}"
        end
        user.projects_by_role.each do |role, projects|
          if role.allowed_to?(permission)
            statement_by_role[role] = "#{Project.table_name}.id IN (#{projects.collect(&:id).join(',')})"
          end
        end
      else
        if Role.anonymous.allowed_to?(permission) && !options[:member]
          statement_by_role[Role.anonymous] = "#{Project.table_name}.is_public = #{connection.quoted_true}"
        end
      end
      if statement_by_role.empty?
        "1=0"
      else
        "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
      end
    end
  end

  # Returns the Systemwide and project specific activities
  def activities(include_inactive=false)
    if include_inactive
      return all_activities
    else
      return active_activities
    end
  end

  # Will create a new Project specific Activity or update an existing one
  #
  # This will raise a ActiveRecord::Rollback if the TimeEntryActivity
  # does not successfully save.
  def update_or_create_time_entry_activity(id, activity_hash)
    if activity_hash.respond_to?(:has_key?) && activity_hash.has_key?('parent_id')
      self.create_time_entry_activity_if_needed(activity_hash)
    else
      activity = project.time_entry_activities.find_by_id(id.to_i)
      activity.update_attributes(activity_hash) if activity
    end
  end

  # Create a new TimeEntryActivity if it overrides a system TimeEntryActivity
  #
  # This will raise a ActiveRecord::Rollback if the TimeEntryActivity
  # does not successfully save.
  def create_time_entry_activity_if_needed(activity)
    if activity['parent_id']

      parent_activity = TimeEntryActivity.find(activity['parent_id'])
      activity['name'] = parent_activity.name
      activity['position'] = parent_activity.position

      if Enumeration.overridding_change?(activity, parent_activity)
        project_activity = self.time_entry_activities.create(activity)

        if project_activity.new_record?
          raise ActiveRecord::Rollback, "Overridding TimeEntryActivity was not successfully saved"
        else
          self.time_entries.update_all("activity_id = #{project_activity.id}", ["activity_id = ?", parent_activity.id])
        end
      end
    end
  end

  # Returns a :conditions SQL string that can be used to find the issues associated with this project.
  #
  # Examples:
  #   project.project_condition(true)  => "(projects.id = 1 OR (projects.lft > 1 AND projects.rgt < 10))"
  #   project.project_condition(false) => "projects.id = 1"
  def project_condition(with_subprojects)
    cond = "#{Project.table_name}.id = #{id}"
    cond = "(#{cond} OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt}))" if with_subprojects
    cond
  end

  def self.find(*args)
    if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
      project = find_by_identifier(*args)
      raise ActiveRecord::RecordNotFound, "Couldn't find Project with identifier=#{args.first}" if project.nil?
      project
    else
      super
    end
  end

  def to_param
    # id is used for projects with a numeric identifier (compatibility)
    @to_param ||= (identifier.to_s =~ %r{^\d*$} ? id : identifier)
  end

  def active?
    self.status == STATUS_ACTIVE
  end

  def archived?
    self.status == STATUS_ARCHIVED
  end

  # Archives the project and its descendants
  def archive
    # Check that there is no issue of a non descendant project that is assigned
    # to one of the project or descendant versions
    v_ids = self_and_descendants.collect {|p| p.version_ids}.flatten
    if v_ids.any? && Issue.find(:first, :include => :project,
                                        :conditions => ["(#{Project.table_name}.lft < ? OR #{Project.table_name}.rgt > ?)" +
                                                        " AND #{Issue.table_name}.fixed_version_id IN (?)", lft, rgt, v_ids])
      return false
    end
    Project.transaction do
      archive!
    end
    true
  end

  # Unarchives the project
  # All its ancestors must be active
  def unarchive
    return false if ancestors.detect {|a| !a.active?}
    update_attribute :status, STATUS_ACTIVE
  end

  # Returns an array of projects the project can be moved to
  # by the current user
  def allowed_parents
    return @allowed_parents if @allowed_parents
    @allowed_parents = Project.find(:all, :conditions => Project.allowed_to_condition(User.current, :add_subprojects))
    @allowed_parents = @allowed_parents - self_and_descendants
    if User.current.allowed_to?(:add_project, nil, :global => true) || (!new_record? && parent.nil?)
      @allowed_parents << nil
    end
    unless parent.nil? || @allowed_parents.empty? || @allowed_parents.include?(parent)
      @allowed_parents << parent
    end
    @allowed_parents
  end

  # Sets the parent of the project with authorization check
  def set_allowed_parent!(p)
    unless p.nil? || p.is_a?(Project)
      if p.to_s.blank?
        p = nil
      else
        p = Project.find_by_id(p)
        return false unless p
      end
    end
    if p.nil?
      if !new_record? && allowed_parents.empty?
        return false
      end
    elsif !allowed_parents.include?(p)
      return false
    end
    set_parent!(p)
  end

  # Sets the parent of the project
  # Argument can be either a Project, a String, a Fixnum or nil
  def set_parent!(p)
    unless p.nil? || p.is_a?(Project)
      if p.to_s.blank?
        p = nil
      else
        p = Project.find_by_id(p)
        return false unless p
      end
    end
    if p == parent && !p.nil?
      # Nothing to do
      true
    elsif p.nil? || (p.active? && move_possible?(p))
      # Insert the project so that target's children or root projects stay alphabetically sorted
      sibs = (p.nil? ? self.class.roots : p.children)
      to_be_inserted_before = sibs.detect {|c| c.name.to_s.downcase > name.to_s.downcase }
      if to_be_inserted_before
        move_to_left_of(to_be_inserted_before)
      elsif p.nil?
        if sibs.empty?
          # move_to_root adds the project in first (ie. left) position
          move_to_root
        else
          move_to_right_of(sibs.last) unless self == sibs.last
        end
      else
        # move_to_child_of adds the project in last (ie.right) position
        move_to_child_of(p)
      end
      Issue.update_versions_from_hierarchy_change(self)
      true
    else
      # Can not move to the given target
      false
    end
  end

  # Returns an array of the trackers used by the project and its active sub projects
  def rolled_up_trackers
    @rolled_up_trackers ||=
      Tracker.find(:all, :joins => :projects,
                         :select => "DISTINCT #{Tracker.table_name}.*",
                         :conditions => ["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ? AND #{Project.table_name}.status = #{STATUS_ACTIVE}", lft, rgt],
                         :order => "#{Tracker.table_name}.position")
  end

  # Closes open and locked project versions that are completed
  def close_completed_versions
    Version.transaction do
      versions.find(:all, :conditions => {:status => %w(open locked)}).each do |version|
        if version.completed?
          version.update_attribute(:status, 'closed')
        end
      end
    end
  end

  # Returns a scope of the Versions on subprojects
  def rolled_up_versions
    @rolled_up_versions ||=
      Version.scoped(:include => :project,
                     :conditions => ["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ? AND #{Project.table_name}.status = #{STATUS_ACTIVE}", lft, rgt])
  end

  # Returns a scope of the Versions used by the project
  def shared_versions
    @shared_versions ||= begin
      r = root? ? self : root
      Version.scoped(:include => :project,
                     :conditions => "#{Project.table_name}.id = #{id}" +
                                    " OR (#{Project.table_name}.status = #{Project::STATUS_ACTIVE} AND (" +
                                          " #{Version.table_name}.sharing = 'system'" +
                                          " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND #{Version.table_name}.sharing = 'tree')" +
                                          " OR (#{Project.table_name}.lft < #{lft} AND #{Project.table_name}.rgt > #{rgt} AND #{Version.table_name}.sharing IN ('hierarchy', 'descendants'))" +
                                          " OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt} AND #{Version.table_name}.sharing = 'hierarchy')" +
                                          "))")
    end
  end

  # Returns a hash of project users grouped by role
  def users_by_role
    members.find(:all, :include => [:user, :roles]).inject({}) do |h, m|
      m.roles.each do |r|
        h[r] ||= []
        h[r] << m.user
      end
      h
    end
  end

  # Deletes all project's members
  def delete_all_members
    me, mr = Member.table_name, MemberRole.table_name
    connection.delete("DELETE FROM #{mr} WHERE #{mr}.member_id IN (SELECT #{me}.id FROM #{me} WHERE #{me}.project_id = #{id})")
    Member.delete_all(['project_id = ?', id])
  end

  # Users issues can be assigned to
  def assignable_users
    members.select {|m| m.roles.detect {|role| role.assignable?}}.collect {|m| m.user}.sort
  end

  # Returns the mail adresses of users that should be always notified on project events
  def recipients
    notified_users.collect {|user| user.mail}
  end

  # Returns the users that should be notified on project events
  def notified_users
    # TODO: User part should be extracted to User#notify_about?
    members.select {|m| m.mail_notification? || m.user.mail_notification == 'all'}.collect {|m| m.user}
  end

  # Returns an array of all custom fields enabled for project issues
  # (explictly associated custom fields and custom fields enabled for all projects)
  def all_issue_custom_fields
    @all_issue_custom_fields ||= (IssueCustomField.for_all + issue_custom_fields).uniq.sort
  end

  def project
    self
  end

  def <=>(project)
    name.downcase <=> project.name.downcase
  end

  def to_s
    name
  end

  # Returns a short description of the projects (first lines)
  def short_description(length = 255)
    description.gsub(/^(.{#{length}}[^\n\r]*).*$/m, '\1...').strip if description
  end

  def css_classes
    s = 'project'
    s << ' root' if root?
    s << ' child' if child?
    s << (leaf? ? ' leaf' : ' parent')
    s
  end

  # The earliest start date of a project, based on it's issues and versions
  def start_date
    [
     issues.minimum('start_date'),
     shared_versions.collect(&:effective_date),
     shared_versions.collect(&:start_date)
    ].flatten.compact.min
  end

  # The latest due date of an issue or version
  def due_date
    [
     issues.maximum('due_date'),
     shared_versions.collect(&:effective_date),
     shared_versions.collect {|v| v.fixed_issues.maximum('due_date')}
    ].flatten.compact.max
  end

  def overdue?
    active? && !due_date.nil? && (due_date < Date.today)
  end

  # Returns the percent completed for this project, based on the
  # progress on it's versions.
  def completed_percent(options={:include_subprojects => false})
    if options.delete(:include_subprojects)
      total = self_and_descendants.collect(&:completed_percent).sum

      total / self_and_descendants.count
    else
      if versions.count > 0
        total = versions.collect(&:completed_pourcent).sum

        total / versions.count
      else
        100
      end
    end
  end

  # Return true if this project is allowed to do the specified action.
  # action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  def allows_to?(action)
    if action.is_a? Hash
      allowed_actions.include? "#{action[:controller]}/#{action[:action]}"
    else
      allowed_permissions.include? action
    end
  end

  def module_enabled?(module_name)
    module_name = module_name.to_s
    enabled_modules.detect {|m| m.name == module_name}
  end

  def enabled_module_names=(module_names)
    if module_names && module_names.is_a?(Array)
      module_names = module_names.collect(&:to_s).reject(&:blank?)
      self.enabled_modules = module_names.collect {|name| enabled_modules.detect {|mod| mod.name == name} || EnabledModule.new(:name => name)}
    else
      enabled_modules.clear
    end
  end

  # Returns an array of the enabled modules names
  def enabled_module_names
    enabled_modules.collect(&:name)
  end

  safe_attributes 'name',
    'description',
    'homepage',
    'is_public',
    'identifier',
    'custom_field_values',
    'custom_fields',
    'tracker_ids',
    'issue_custom_field_ids'

  safe_attributes 'enabled_module_names',
    :if => lambda {|project, user| project.new_record? || user.allowed_to?(:select_project_modules, project) }

  # Returns an array of projects that are in this project's hierarchy
  #
  # Example: parents, children, siblings
  def hierarchy
    parents = project.self_and_ancestors || []
    descendants = project.descendants || []
    project_hierarchy = parents | descendants # Set union
  end

  # Returns an auto-generated project identifier based on the last identifier used
  def self.next_identifier
    p = Project.find(:first, :order => 'created_on DESC')
    p.nil? ? nil : p.identifier.to_s.succ
  end

  # Copies and saves the Project instance based on the +project+.
  # Duplicates the source project's:
  # * Wiki
  # * Versions
  # * Categories
  # * Issues
  # * Members
  # * Queries
  #
  # Accepts an +options+ argument to specify what to copy
  #
  # Examples:
  #   project.copy(1)                                    # => copies everything
  #   project.copy(1, :only => 'members')                # => copies members only
  #   project.copy(1, :only => ['members', 'versions'])  # => copies members and versions
  def copy(project, options={})
    project = project.is_a?(Project) ? project : Project.find(project)

    to_be_copied = %w(wiki versions issue_categories issues members queries boards)
    to_be_copied = to_be_copied & options[:only].to_a unless options[:only].nil?

    Project.transaction do
      if save
        reload
        to_be_copied.each do |name|
          send "copy_#{name}", project
        end
        Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self)
        save
      end
    end
  end


  # Copies +project+ and returns the new instance.  This will not save
  # the copy
  def self.copy_from(project)
    begin
      project = project.is_a?(Project) ? project : Project.find(project)
      if project
        # clear unique attributes
        attributes = project.attributes.dup.except('id', 'name', 'identifier', 'status', 'parent_id', 'lft', 'rgt')
        copy = Project.new(attributes)
        copy.enabled_modules = project.enabled_modules
        copy.trackers = project.trackers
        copy.custom_values = project.custom_values.collect {|v| v.clone}
        copy.issue_custom_fields = project.issue_custom_fields
        return copy
      else
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  # Yields the given block for each project with its level in the tree
  def self.project_tree(projects, &block)
    ancestors = []
    projects.sort_by(&:lft).each do |project|
      while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield project, ancestors.size if block_given?
      ancestors << project
    end
  end

  private

  # Copies wiki from +project+
  def copy_wiki(project)
    # Check that the source project has a wiki first
    unless project.wiki.nil?
      self.wiki ||= Wiki.new
      wiki.attributes = project.wiki.attributes.dup.except("id", "project_id")
      wiki_pages_map = {}
      project.wiki.pages.each do |page|
        # Skip pages without content
        next if page.content.nil?
        new_wiki_content = WikiContent.new(page.content.attributes.dup.except("id", "page_id", "updated_on"))
        new_wiki_page = WikiPage.new(page.attributes.dup.except("id", "wiki_id", "created_on", "parent_id"))
        new_wiki_page.content = new_wiki_content
        wiki.pages << new_wiki_page
        wiki_pages_map[page.id] = new_wiki_page
      end
      wiki.save
      # Reproduce page hierarchy
      project.wiki.pages.each do |page|
        if page.parent_id && wiki_pages_map[page.id]
          wiki_pages_map[page.id].parent = wiki_pages_map[page.parent_id]
          wiki_pages_map[page.id].save
        end
      end
    end
  end

  # Copies versions from +project+
  def copy_versions(project)
    project.versions.each do |version|
      new_version = Version.new
      new_version.attributes = version.attributes.dup.except("id", "project_id", "created_on", "updated_on")
      self.versions << new_version
    end
  end

  # Copies issue categories from +project+
  def copy_issue_categories(project)
    project.issue_categories.each do |issue_category|
      new_issue_category = IssueCategory.new
      new_issue_category.attributes = issue_category.attributes.dup.except("id", "project_id")
      self.issue_categories << new_issue_category
    end
  end

  # Copies issues from +project+
  def copy_issues(project)
    # Stores the source issue id as a key and the copied issues as the
    # value.  Used to map the two togeather for issue relations.
    issues_map = {}

    # Get issues sorted by root_id, lft so that parent issues
    # get copied before their children
    project.issues.find(:all, :order => 'root_id, lft').each do |issue|
      new_issue = Issue.new
      new_issue.copy_from(issue)
      new_issue.project = self
      # Reassign fixed_versions by name, since names are unique per
      # project and the versions for self are not yet saved
      if issue.fixed_version
        new_issue.fixed_version = self.versions.select {|v| v.name == issue.fixed_version.name}.first
      end
      # Reassign the category by name, since names are unique per
      # project and the categories for self are not yet saved
      if issue.category
        new_issue.category = self.issue_categories.select {|c| c.name == issue.category.name}.first
      end
      # Parent issue
      if issue.parent_id
        if copied_parent = issues_map[issue.parent_id]
          new_issue.parent_issue_id = copied_parent.id
        end
      end

      self.issues << new_issue
      if new_issue.new_record?
        logger.info "Project#copy_issues: issue ##{issue.id} could not be copied: #{new_issue.errors.full_messages}" if logger && logger.info
      else
        issues_map[issue.id] = new_issue unless new_issue.new_record?
      end
    end

    # Relations after in case issues related each other
    project.issues.each do |issue|
      new_issue = issues_map[issue.id]
      unless new_issue
        # Issue was not copied
        next
      end

      # Relations
      issue.relations_from.each do |source_relation|
        new_issue_relation = IssueRelation.new
        new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
        new_issue_relation.issue_to = issues_map[source_relation.issue_to_id]
        if new_issue_relation.issue_to.nil? && Setting.cross_project_issue_relations?
          new_issue_relation.issue_to = source_relation.issue_to
        end
        new_issue.relations_from << new_issue_relation
      end

      issue.relations_to.each do |source_relation|
        new_issue_relation = IssueRelation.new
        new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
        new_issue_relation.issue_from = issues_map[source_relation.issue_from_id]
        if new_issue_relation.issue_from.nil? && Setting.cross_project_issue_relations?
          new_issue_relation.issue_from = source_relation.issue_from
        end
        new_issue.relations_to << new_issue_relation
      end
    end
  end

  # Copies members from +project+
  def copy_members(project)
    # Copy users first, then groups to handle members with inherited and given roles
    members_to_copy = []
    members_to_copy += project.memberships.select {|m| m.principal.is_a?(User)}
    members_to_copy += project.memberships.select {|m| !m.principal.is_a?(User)}

    members_to_copy.each do |member|
      new_member = Member.new
      new_member.attributes = member.attributes.dup.except("id", "project_id", "created_on")
      # only copy non inherited roles
      # inherited roles will be added when copying the group membership
      role_ids = member.member_roles.reject(&:inherited?).collect(&:role_id)
      next if role_ids.empty?
      new_member.role_ids = role_ids
      new_member.project = self
      self.members << new_member
    end
  end

  # Copies queries from +project+
  def copy_queries(project)
    project.queries.each do |query|
      new_query = Query.new
      new_query.attributes = query.attributes.dup.except("id", "project_id", "sort_criteria")
      new_query.sort_criteria = query.sort_criteria if query.sort_criteria
      new_query.project = self
      self.queries << new_query
    end
  end

  # Copies boards from +project+
  def copy_boards(project)
    project.boards.each do |board|
      new_board = Board.new
      new_board.attributes = board.attributes.dup.except("id", "project_id", "topics_count", "messages_count", "last_message_id")
      new_board.project = self
      self.boards << new_board
    end
  end

  def allowed_permissions
    @allowed_permissions ||= begin
      module_names = enabled_modules.all(:select => :name).collect {|m| m.name}
      Redmine::AccessControl.modules_permissions(module_names).collect {|p| p.name}
    end
  end

  def allowed_actions
    @actions_allowed ||= allowed_permissions.inject([]) { |actions, permission| actions += Redmine::AccessControl.allowed_actions(permission) }.flatten
  end

  # Returns all the active Systemwide and project specific activities
  def active_activities
    overridden_activity_ids = self.time_entry_activities.collect(&:parent_id)

    if overridden_activity_ids.empty?
      return TimeEntryActivity.shared.active
    else
      return system_activities_and_project_overrides
    end
  end

  # Returns all the Systemwide and project specific activities
  # (inactive and active)
  def all_activities
    overridden_activity_ids = self.time_entry_activities.collect(&:parent_id)

    if overridden_activity_ids.empty?
      return TimeEntryActivity.shared
    else
      return system_activities_and_project_overrides(true)
    end
  end

  # Returns the systemwide active activities merged with the project specific overrides
  def system_activities_and_project_overrides(include_inactive=false)
    if include_inactive
      return TimeEntryActivity.shared.
        find(:all,
             :conditions => ["id NOT IN (?)", self.time_entry_activities.collect(&:parent_id)]) +
        self.time_entry_activities
    else
      return TimeEntryActivity.shared.active.
        find(:all,
             :conditions => ["id NOT IN (?)", self.time_entry_activities.collect(&:parent_id)]) +
        self.time_entry_activities.active
    end
  end

  # Archives subprojects recursively
  def archive!
    children.each do |subproject|
      subproject.send :archive!
    end
    update_attribute :status, STATUS_ARCHIVED
  end
end

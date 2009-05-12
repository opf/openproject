# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class Project < ActiveRecord::Base
  # Project statuses
  STATUS_ACTIVE     = 1
  STATUS_ARCHIVED   = 9
  
  has_many :members, :include => :user, :conditions => "#{User.table_name}.status=#{User::STATUS_ACTIVE}"
  has_many :users, :through => :members
  has_many :enabled_modules, :dependent => :delete_all
  has_and_belongs_to_many :trackers, :order => "#{Tracker.table_name}.position"
  has_many :issues, :dependent => :destroy, :order => "#{Issue.table_name}.created_on DESC", :include => [:status, :tracker]
  has_many :issue_changes, :through => :issues, :source => :journals
  has_many :versions, :dependent => :destroy, :order => "#{Version.table_name}.effective_date DESC, #{Version.table_name}.name DESC"
  has_many :time_entries, :dependent => :delete_all
  has_many :queries, :dependent => :delete_all
  has_many :documents, :dependent => :destroy
  has_many :news, :dependent => :delete_all, :include => :author
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
  acts_as_searchable :columns => ['name', 'description'], :project_key => 'id', :permission => nil
  acts_as_event :title => Proc.new {|o| "#{l(:label_project)}: #{o.name}"},
                :url => Proc.new {|o| {:controller => 'projects', :action => 'show', :id => o.id}},
                :author => nil

  attr_protected :status, :enabled_module_names
  
  validates_presence_of :name, :identifier
  validates_uniqueness_of :name, :identifier
  validates_associated :repository, :wiki
  validates_length_of :name, :maximum => 30
  validates_length_of :homepage, :maximum => 255
  validates_length_of :identifier, :in => 1..20
  validates_format_of :identifier, :with => /^[a-z0-9\-]*$/
  
  before_destroy :delete_all_members

  named_scope :has_module, lambda { |mod| { :conditions => ["#{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name=?)", mod.to_s] } }
  named_scope :active, { :conditions => "#{Project.table_name}.status = #{STATUS_ACTIVE}"}
  named_scope :public, { :conditions => { :is_public => true } }
  named_scope :visible, lambda { { :conditions => Project.visible_by(User.current) } }
  
  def identifier=(identifier)
    super unless identifier_frozen?
  end
  
  def identifier_frozen?
    errors[:identifier].nil? && !(new_record? || identifier.blank?)
  end
  
  def issues_with_subprojects(include_subprojects=false)
    conditions = nil
    if include_subprojects
      ids = [id] + descendants.collect(&:id)
      conditions = ["#{Project.table_name}.id IN (#{ids.join(',')}) AND #{Project.visible_by}"]
    end
    conditions ||= ["#{Project.table_name}.id = ?", id]
    # Quick and dirty fix for Rails 2 compatibility
    Issue.send(:with_scope, :find => { :conditions => conditions }) do 
      Version.send(:with_scope, :find => { :conditions => conditions }) do
        yield
      end
    end 
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
    statements = []
    base_statement = "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
    if perm = Redmine::AccessControl.permission(permission)
      unless perm.project_module.nil?
        # If the permission belongs to a project module, make sure the module is enabled
        base_statement << " AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}' AND em.project_id=#{Project.table_name}.id)"
      end
    end
    if options[:project]
      project_statement = "#{Project.table_name}.id = #{options[:project].id}"
      project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
      base_statement = "(#{project_statement}) AND (#{base_statement})"
    end
    if user.admin?
      # no restriction
    else
      statements << "1=0"
      if user.logged?
        statements << "#{Project.table_name}.is_public = #{connection.quoted_true}" if Role.non_member.allowed_to?(permission)
        allowed_project_ids = user.memberships.select {|m| m.roles.detect {|role| role.allowed_to?(permission)}}.collect {|m| m.project_id}
        statements << "#{Project.table_name}.id IN (#{allowed_project_ids.join(',')})" if allowed_project_ids.any?
      elsif Role.anonymous.allowed_to?(permission)
        # anonymous user allowed on public project
        statements << "#{Project.table_name}.is_public = #{connection.quoted_true}" 
      else
        # anonymous user is not authorized
      end
    end
    statements.empty? ? base_statement : "((#{base_statement}) AND (#{statements.join(' OR ')}))"
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
  
  # Archives the project and its descendants recursively
  def archive
    # Archive subprojects if any
    children.each do |subproject|
      subproject.archive
    end
    update_attribute :status, STATUS_ARCHIVED
  end
  
  # Unarchives the project
  # All its ancestors must be active
  def unarchive
    return false if ancestors.detect {|a| !a.active?}
    update_attribute :status, STATUS_ACTIVE
  end
  
  # Returns an array of projects the project can be moved to
  def possible_parents
    @possible_parents ||= (Project.active.find(:all) - self_and_descendants)
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
      true
    else
      # Can not move to the given target
      false
    end
  end
  
  # Returns an array of the trackers used by the project and its active sub projects
  def rolled_up_trackers
    @rolled_up_trackers ||=
      Tracker.find(:all, :include => :projects,
                         :select => "DISTINCT #{Tracker.table_name}.*",
                         :conditions => ["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ? AND #{Project.table_name}.status = #{STATUS_ACTIVE}", lft, rgt],
                         :order => "#{Tracker.table_name}.position")
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
    members.select {|m| m.mail_notification? || m.user.mail_notification?}.collect {|m| m.user.mail}
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
      module_names = module_names.collect(&:to_s)
      # remove disabled modules
      enabled_modules.each {|mod| mod.destroy unless module_names.include?(mod.name)}
      # add new modules
      module_names.each {|name| enabled_modules << EnabledModule.new(:name => name)}
    else
      enabled_modules.clear
    end
  end
  
  # Returns an auto-generated project identifier based on the last identifier used
  def self.next_identifier
    p = Project.find(:first, :order => 'created_on DESC')
    p.nil? ? nil : p.identifier.to_s.succ
  end

  # Copies and saves the Project instance based on the +project+.
  # Will duplicate the source project's:
  # * Issues
  # * Members
  # * Queries
  def copy(project)
    project = project.is_a?(Project) ? project : Project.find(project)

    Project.transaction do
      # Issues
      project.issues.each do |issue|
        new_issue = Issue.new
        new_issue.copy_from(issue)
        self.issues << new_issue
      end
    
      # Members
      project.members.each do |member|
        new_member = Member.new
        new_member.attributes = member.attributes.dup.except("project_id")
        new_member.role_ids = member.role_ids.dup
        new_member.project = self
        self.members << new_member
      end
      
      # Queries
      project.queries.each do |query|
        new_query = Query.new
        new_query.attributes = query.attributes.dup.except("project_id", "sort_criteria")
        new_query.sort_criteria = query.sort_criteria if query.sort_criteria
        new_query.project = self
        self.queries << new_query
      end

      Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self)
      self.save
    end
  end

  
  # Copies +project+ and returns the new instance.  This will not save
  # the copy
  def self.copy_from(project)
    begin
      project = project.is_a?(Project) ? project : Project.find(project)
      if project
        # clear unique attributes
        attributes = project.attributes.dup.except('name', 'identifier', 'id', 'status')
        copy = Project.new(attributes)
        copy.enabled_modules = project.enabled_modules
        copy.trackers = project.trackers
        copy.custom_values = project.custom_values.collect {|v| v.clone}
        return copy
      else
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
  
protected
  def validate
    errors.add(:identifier, :invalid) if !identifier.blank? && identifier.match(/^\d*$/)
  end
  
private
  def allowed_permissions
    @allowed_permissions ||= begin
      module_names = enabled_modules.collect {|m| m.name}
      Redmine::AccessControl.modules_permissions(module_names).collect {|p| p.name}
    end
  end

  def allowed_actions
    @actions_allowed ||= allowed_permissions.inject([]) { |actions, permission| actions += Redmine::AccessControl.allowed_actions(permission) }.flatten
  end
end

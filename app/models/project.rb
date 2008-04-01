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
  has_many :custom_values, :dependent => :delete_all, :as => :customized
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
  has_and_belongs_to_many :custom_fields, 
                          :class_name => 'IssueCustomField',
                          :order => "#{CustomField.table_name}.position",
                          :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
                          :association_foreign_key => 'custom_field_id'
                          
  acts_as_tree :order => "name", :counter_cache => true

  acts_as_searchable :columns => ['name', 'description'], :project_key => 'id'
  acts_as_event :title => Proc.new {|o| "#{l(:label_project)}: #{o.name}"},
                :url => Proc.new {|o| {:controller => 'projects', :action => 'show', :id => o.id}}

  attr_protected :status, :enabled_module_names
  
  validates_presence_of :name, :identifier
  validates_uniqueness_of :name, :identifier
  validates_associated :custom_values, :on => :update
  validates_associated :repository, :wiki
  validates_length_of :name, :maximum => 30
  validates_length_of :homepage, :maximum => 60
  validates_length_of :identifier, :in => 3..20
  validates_format_of :identifier, :with => /^[a-z0-9\-]*$/
  
  before_destroy :delete_all_members
  
  def identifier=(identifier)
    super unless identifier_frozen?
  end
  
  def identifier_frozen?
    errors[:identifier].nil? && !(new_record? || identifier.blank?)
  end
  
  def issues_with_subprojects(include_subprojects=false)
    conditions = nil
    if include_subprojects && !active_children.empty?
      ids = [id] + active_children.collect {|c| c.id}
      conditions = ["#{Issue.table_name}.project_id IN (#{ids.join(',')})"]
    end
    conditions ||= ["#{Issue.table_name}.project_id = ?", id]
    # Quick and dirty fix for Rails 2 compatibility
    Issue.send(:with_scope, :find => { :conditions => conditions }) do 
      yield
    end 
  end

  # returns latest created projects
  # non public projects will be returned only if user is a member of those
  def self.latest(user=nil, count=5)
    find(:all, :limit => count, :conditions => visible_by(user), :order => "created_on DESC")	
  end	

  def self.visible_by(user=nil)
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
    if options[:project]
      project_statement = "#{Project.table_name}.id = #{options[:project].id}"
      project_statement << " OR #{Project.table_name}.parent_id = #{options[:project].id}" if options[:with_subprojects]
      base_statement = "(#{project_statement}) AND (#{base_statement})"
    end
    if user.admin?
      # no restriction
    elsif user.logged?
      statements << "#{Project.table_name}.is_public = #{connection.quoted_true}" if Role.non_member.allowed_to?(permission)
      allowed_project_ids = user.memberships.select {|m| m.role.allowed_to?(permission)}.collect {|m| m.project_id}
      statements << "#{Project.table_name}.id IN (#{allowed_project_ids.join(',')})" if allowed_project_ids.any?
    elsif Role.anonymous.allowed_to?(permission)
      # anonymous user allowed on public project
      statements << "#{Project.table_name}.is_public = #{connection.quoted_true}" 
    else
      # anonymous user is not authorized
      statements << "1=0"
    end
    statements.empty? ? base_statement : "((#{base_statement}) AND (#{statements.join(' OR ')}))"
  end
  
  def project_condition(with_subprojects)
    cond = "#{Project.table_name}.id = #{id}"
    cond = "(#{cond} OR #{Project.table_name}.parent_id = #{id})" if with_subprojects
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
    identifier
  end
  
  def active?
    self.status == STATUS_ACTIVE
  end
  
  def archive
    # Archive subprojects if any
    children.each do |subproject|
      subproject.archive
    end
    update_attribute :status, STATUS_ARCHIVED
  end
  
  def unarchive
    return false if parent && !parent.active?
    update_attribute :status, STATUS_ACTIVE
  end
  
  def active_children
    children.select {|child| child.active?}
  end
  
  # Returns an array of the trackers used by the project and its sub projects
  def rolled_up_trackers
    @rolled_up_trackers ||=
      Tracker.find(:all, :include => :projects,
                         :select => "DISTINCT #{Tracker.table_name}.*",
                         :conditions => ["#{Project.table_name}.id = ? OR #{Project.table_name}.parent_id = ?", id, id],
                         :order => "#{Tracker.table_name}.position")
  end
  
  # Deletes all project's members
  def delete_all_members
    Member.delete_all(['project_id = ?', id])
  end
  
  # Users issues can be assigned to
  def assignable_users
    members.select {|m| m.role.assignable?}.collect {|m| m.user}.sort
  end
  
  # Returns the mail adresses of users that should be always notified on project events
  def recipients
    members.select {|m| m.mail_notification? || m.user.mail_notification?}.collect {|m| m.user.mail}
  end
  
  # Returns an array of all custom fields enabled for project issues
  # (explictly associated custom fields and custom fields enabled for all projects)
  def custom_fields_for_issues(tracker)
    all_custom_fields.select {|c| tracker.custom_fields.include? c }
  end
  
  def all_custom_fields
    @all_custom_fields ||= (IssueCustomField.for_all + custom_fields).uniq
  end
  
  def <=>(project)
    name.downcase <=> project.name.downcase
  end
  
  def to_s
    name
  end
  
  # Returns a short description of the projects (first lines)
  def short_description(length = 255)
    description.gsub(/^(.{#{length}}[^\n]*).*$/m, '\1').strip if description
  end
  
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
    enabled_modules.clear
    module_names = [] unless module_names && module_names.is_a?(Array)
    module_names.each do |name|
      enabled_modules << EnabledModule.new(:name => name.to_s)
    end
  end

protected
  def validate
    errors.add(parent_id, " must be a root project") if parent and parent.parent
    errors.add_to_base("A project with subprojects can't be a subproject") if parent and children.size > 0
    errors.add(:identifier, :activerecord_error_invalid) if !identifier.blank? && identifier.match(/^\d*$/)
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

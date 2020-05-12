#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Project < ApplicationRecord
  extend Pagination::Model
  extend FriendlyId

  include Projects::Copy
  include Projects::Storage
  include Projects::Activity
  include ::Scopes::Scoped

  # Maximum length for project identifiers
  IDENTIFIER_MAX_LENGTH = 100

  # reserved identifiers
  RESERVED_IDENTIFIERS = %w(new).freeze

  has_many :members, -> {
    includes(:principal, :roles)
      .where(
        "#{Principal.table_name}.type='User' AND (
          #{User.table_name}.status=#{Principal::STATUSES[:active]} OR
          #{User.table_name}.status=#{Principal::STATUSES[:invited]}
        )"
      )
      .references(:principal, :roles)
  }

  has_many :possible_assignee_members, -> {
    includes(:principal, :roles)
      .where(Project.possible_principles_condition)
      .references(:principals, :roles)
  }, class_name: 'Member'
  # Read only
  has_many :possible_assignees,
           ->(object) {
             # Have to reference members and roles again although
             # possible_assignee_members does already specify it to be able to use the
             # Project.possible_principles_condition there
             #
             # The .where(members_users: { project_id: object.id })
             # part is an optimization preventing to have all the members joined
             includes(members: :roles)
               .where(members_users: { project_id: object.id })
               .references(:roles)
               .merge(Principal.order_by_name)
           },
           through: :possible_assignee_members,
           source: :principal
  has_many :possible_responsible_members, -> {
    includes(:principal, :roles)
      .where(Project.possible_principles_condition)
      .references(:principals, :roles)
  }, class_name: 'Member'
  # Read only
  has_many :possible_responsibles,
           ->(object) {
             # Have to reference members and roles again although
             # possible_responsible_members does already specify it to be able to use
             # the Project.possible_principles_condition there
             #
             # The .where(members_users: { project_id: object.id })
             # part is an optimization preventing to have all the members joined
             includes(members: :roles)
               .where(members_users: { project_id: object.id })
               .references(:roles)
               .merge(Principal.order_by_name)
           },
           through: :possible_responsible_members,
           source: :principal
  has_many :memberships, class_name: 'Member'
  has_many :member_principals,
           -> {
             includes(:principal)
               .references(:principals)
               .where("#{Principal.table_name}.type='Group' OR " +
               "(#{Principal.table_name}.type='User' AND " +
               "(#{Principal.table_name}.status=#{Principal::STATUSES[:active]} OR " +
               "#{Principal.table_name}.status=#{Principal::STATUSES[:registered]} OR " +
               "#{Principal.table_name}.status=#{Principal::STATUSES[:invited]}))")
           },
           class_name: 'Member'
  has_many :users, through: :members, source: :principal
  has_many :principals, through: :member_principals, source: :principal

  has_many :enabled_modules, dependent: :delete_all
  has_and_belongs_to_many :types, -> {
    order("#{::Type.table_name}.position")
  }
  has_many :work_packages, -> {
    order("#{WorkPackage.table_name}.created_at DESC")
      .includes(:status, :type)
  }
  has_many :work_package_changes, through: :work_packages, source: :journals
  has_many :versions, -> {
    order("#{Version.table_name}.effective_date DESC, #{Version.table_name}.name DESC")
  }, dependent: :destroy
  has_many :time_entries, dependent: :delete_all
  has_many :time_entry_activities_projects, dependent: :delete_all
  has_many :queries, dependent: :delete_all
  has_many :news, -> { includes(:author) }, dependent: :destroy
  has_many :categories, -> { order("#{Category.table_name}.name") }, dependent: :delete_all
  has_many :forums, -> { order('position ASC') }, dependent: :destroy
  has_one :repository, dependent: :destroy
  has_many :changesets, through: :repository
  has_one :wiki, dependent: :destroy
  # Custom field for the project's work_packages
  has_and_belongs_to_many :work_package_custom_fields, -> {
    order("#{CustomField.table_name}.position")
  }, class_name: 'WorkPackageCustomField',
     join_table: "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
     association_foreign_key: 'custom_field_id'
  has_one :status, class_name: 'Projects::Status', dependent: :destroy

  acts_as_nested_set order_column: :name, dependent: :destroy

  acts_as_customizable
  acts_as_searchable columns: %W(#{table_name}.name #{table_name}.identifier #{table_name}.description),
                     date_column: "#{table_name}.created_at",
                     project_key: 'id',
                     permission: nil
  acts_as_event title: Proc.new { |o| "#{Project.model_name.human}: #{o.name}" },
                url: Proc.new { |o| { controller: 'overviews/overviews', action: 'show', project_id: o } },
                author: nil,
                datetime: :created_at

  validates :name,
            presence: true,
            length: { maximum: 255 }
  # TODO: we temporarily disable this validation because it leads to failed tests
  # it implicitly assumes a db:seed-created standard type to be present and currently
  # neither development nor deployment setups are prepared for this
  # validates_presence_of :types
  validates :identifier,
            presence: true,
            uniqueness: { case_sensitive: true },
            length: { maximum: IDENTIFIER_MAX_LENGTH },
            exclusion: RESERVED_IDENTIFIERS

  validates_associated :repository, :wiki
  # starts with lower-case letter, a-z, 0-9, dashes and underscores afterwards
  validates :identifier,
            format: { with: /\A[a-z][a-z0-9\-_]*\z/ },
            if: ->(p) { p.identifier_changed? }
  # reserved words

  friendly_id :identifier, use: :finders

  scope :has_module, ->(mod) {
    where(["#{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name=?)", mod.to_s])
  }
  scope :public_projects, -> { where(public: true) }
  scope :visible, ->(user = User.current) { merge(Project.visible_by(user)) }
  scope :newest, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }

  scope_classes Projects::Scopes::ActivatedTimeActivity,
                Projects::Scopes::VisibleWithActivatedTimeActivity

  def visible?(user = User.current)
    active? and (public? or user.admin? or user.member_of?(self))
  end

  def archived?
    !active?
  end

  def copy_allowed?
    User.current.allowed_to?(:copy_projects, self)
  end

  def self.selectable_projects
    Project.visible.select { |p| User.current.member_of? p }.sort_by(&:to_s)
  end

  def self.search_scope(query)
    # overwritten from Pagination::Model
    visible.like(query)
  end

  def possible_members(criteria, limit)
    Principal.active_or_registered.like(criteria).not_in_project(self).limit(limit)
  end

  def add_member(user, roles)
    members.build.tap do |m|
      m.principal = user
      m.roles = Array(roles)
    end
  end

  def add_member!(user, roles)
    add_member(user, roles)
    save
  end

  # Returns all projects the user is allowed to see.
  #
  # Employs the :view_project permission to perform the
  # authorization check as the permissino is public, meaning it is granted
  # to everybody having at least one role in a project regardless of the
  # role's permissions.
  def self.visible_by(user = User.current)
    allowed_to(user, :view_project)
  end

  # Returns a ActiveRecord::Relation to find all projects for which
  # +user+ has the given +permission+
  def self.allowed_to(user, permission)
    Authorization.projects(permission, user)
  end

  def reload(*args)
    @all_work_package_custom_fields = nil

    super
  end

  # Returns a :conditions SQL string that can be used to find the issues associated with this project.
  #
  # Examples:
  #   project.project_condition(true)  => "(projects.id = 1 OR (projects.lft > 1 AND projects.rgt < 10))"
  #   project.project_condition(false) => "projects.id = 1"
  def project_condition(with_subprojects)
    projects_table = Project.arel_table

    stmt = projects_table[:id].eq(id)
    stmt = stmt.or(projects_table[:lft].gt(lft).and(projects_table[:rgt].lt(rgt))) if with_subprojects
    stmt
  end

  def types_used_by_work_packages
    ::Type.where(id: WorkPackage.where(project_id: project.id)
                                .select(:type_id)
                                .distinct)
  end

  # Returns a scope of the types used by the project and its active sub projects
  def rolled_up_types
    ::Type
      .joins(:projects)
      .select("DISTINCT #{::Type.table_name}.*")
      .where(projects: { id: self_and_descendants.select(:id) })
      .merge(Project.active)
      .order("#{::Type.table_name}.position")
  end

  # Closes open and locked project versions that are completed
  def close_completed_versions
    Version.transaction do
      versions.where(status: %w(open locked)).each do |version|
        if version.completed?
          version.update_attribute(:status, 'closed')
        end
      end
    end
  end

  # Returns a scope of the Versions on subprojects
  def rolled_up_versions
    shared_versions_base_scope
      .merge(Project.active)
      .where(projects: { id: self_and_descendants.select(:id) })
  end

  # Returns a scope of the Versions used by the project
  def shared_versions
    if persisted?
      shared_versions_on_persisted
    else
      shared_versions_by_system
    end
  end

  # Returns all versions a work package can be assigned to.  Opposed to
  # #shared_versions this returns an array of Versions, not a scope.
  #
  # The main benefit is in scenarios where work packages' projects are eager
  # loaded.  Because eager loading the project e.g. via
  # WorkPackage.includes(:project).where(type: 5) will assign the same instance
  # (same object_id) for every work package having the same project this will
  # reduce the number of db queries when performing operations including the
  # project's versions.
  def assignable_versions
    @all_shared_versions ||= shared_versions.with_status_open.order_by_semver_name.to_a
  end

  # Returns a hash of project users grouped by role
  def users_by_role
    members.includes(:principal, :roles).inject({}) do |h, m|
      m.roles.each do |r|
        h[r] ||= []
        h[r] << m.principal
      end
      h
    end
  end

  # Returns users that should be always notified on project events
  def recipients
    notified_users
  end

  # Returns the users that should be notified on project events
  def notified_users
    # TODO: User part should be extracted to User#notify_about?
    notified_members = members.select do |member|
      setting = member.principal.mail_notification

      (setting == 'selected' && member.mail_notification?) || setting == 'all'
    end

    notified_members.map(&:principal)
  end

  # Returns an array of all custom fields enabled for project issues
  # (explictly associated custom fields and custom fields enabled for all projects)
  #
  # Supports the :include option.
  def all_work_package_custom_fields(options = {})
    @all_work_package_custom_fields ||= (
      WorkPackageCustomField.for_all(options) + (
        if options.include? :include
          WorkPackageCustomField.joins(:projects)
            .where(projects: { id: id })
            .includes(options[:include]) # use #preload instead of #includes if join gets too big
        else
          work_package_custom_fields
        end
      )
    ).uniq.sort
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

  # Return true if this project is allowed to do the specified action.
  # action can be:
  # * a parameter-like Hash (eg. controller: '/projects', action: 'edit')
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
    enabled_modules.any? { |m| m.name == module_name }
  end

  def enabled_module_names=(module_names)
    if module_names&.is_a?(Array)
      module_names = module_names.map(&:to_s).reject(&:blank?)
      self.enabled_modules = module_names.map { |name| enabled_modules.detect { |mod| mod.name == name } || EnabledModule.new(name: name) }
    else
      enabled_modules.clear
    end
  end

  # Returns an array of the enabled modules names
  def enabled_module_names
    enabled_modules.map(&:name)
  end

  # Returns an array of projects that are in this project's hierarchy
  #
  # Example: parents, children, siblings
  def hierarchy
    parents = project.self_and_ancestors || []
    descendants = project.descendants || []
    parents | descendants # Set union
  end

  class << self
    # Returns an auto-generated project identifier based on the last identifier used
    def next_identifier
      p = Project.newest.first
      p.nil? ? nil : p.identifier.to_s.succ
    end

    # builds up a project hierarchy helper structure for use with #project_tree_from_hierarchy
    #
    # it expects a simple list of projects with a #lft column (awesome_nested_set)
    # and returns a hierarchy based on #lft
    #
    # the result is a nested list of root level projects that contain their child projects
    # but, each entry is actually a ruby hash wrapping the project and child projects
    # the keys are :project and :children where :children is in the same format again
    #
    #   result = [ root_level_project_info_1, root_level_project_info_2, ... ]
    #
    # where each entry has the form
    #
    #   project_info = { project: the_project, children: [ child_info_1, child_info_2, ... ] }
    #
    # if a project has no children the :children array is just empty
    #
    def build_projects_hierarchy(projects)
      ancestors = []
      result    = []

      projects.sort_by(&:lft).each do |project|
        while ancestors.any? && !project.is_descendant_of?(ancestors.last[:project])
          # before we pop back one level, we sort the child projects by name
          ancestors.last[:children] = sort_by_name(ancestors.last[:children])
          ancestors.pop
        end

        current_hierarchy = { project: project, children: [] }
        current_tree      = ancestors.any? ? ancestors.last[:children] : result

        current_tree << current_hierarchy
        ancestors << current_hierarchy
      end

      # When the last project is deeply nested, we need to sort
      # all layers we are in.
      ancestors.each do |level|
        level[:children] = sort_by_name(level[:children])
      end
      # we need one extra element to ensure sorting at the end
      # at the end the root level must be sorted as well
      sort_by_name(result)
    end

    def project_tree_from_hierarchy(projects_hierarchy, level, &block)
      projects_hierarchy.each do |hierarchy|
        project = hierarchy[:project]
        children = hierarchy[:children]
        yield project, level
        # recursively show children
        project_tree_from_hierarchy(children, level + 1, &block) if children.any?
      end
    end

    # Yields the given block for each project with its level in the tree
    def project_tree(projects, &block)
      projects_hierarchy = build_projects_hierarchy(projects)
      project_tree_from_hierarchy(projects_hierarchy, 0, &block)
    end

    def project_level_list(projects)
      list = []
      project_tree(projects) do |project, level|
        element = {
          project: project,
          level: level
        }

        element.merge!(yield(project)) if block_given?

        list << element
      end
      list
    end

    private

    def sort_by_name(project_hashes)
      project_hashes.sort_by { |h| h[:project].name&.downcase }
    end
  end

  def allowed_permissions
    @allowed_permissions ||= begin
      names = enabled_modules.loaded? ? enabled_module_names : enabled_modules.pluck(:name)

      OpenProject::AccessControl.modules_permissions(names).map(&:name)
    end
  end

  def allowed_actions
    @actions_allowed ||= allowed_permissions
                         .map { |permission| OpenProject::AccessControl.allowed_actions(permission) }
                         .flatten
  end

  def self.possible_principles_condition
    condition = if Setting.work_package_group_assignment?
                  ["(#{Principal.table_name}.type=? OR #{Principal.table_name}.type=?)", 'User', 'Group']
                else
                  ["(#{Principal.table_name}.type=?)", 'User']
                end

    condition[0] += " AND (#{User.table_name}.status=? OR #{User.table_name}.status=?) AND roles.assignable = ?"
    condition << Principal::STATUSES[:active]
    condition << Principal::STATUSES[:invited]
    condition << true

    sanitize_sql_array condition
  end

  protected

  def shared_versions_on_persisted
    shared_versions_base_scope
      .where(projects: { id: id })
      .or(shared_versions_by_system)
      .or(shared_versions_by_tree)
      .or(shared_versions_by_hierarchy_or_descendants)
      .or(shared_versions_by_hierarchy)
  end

  def shared_versions_by_tree
    r = root? ? self : root

    shared_versions_base_scope
      .merge(Project.active)
      .where(projects: { id: r.self_and_descendants.select(:id) })
      .where(sharing: 'tree')
  end

  def shared_versions_by_hierarchy_or_descendants
    shared_versions_base_scope
      .merge(Project.active)
      .where(projects: { id: ancestors.select(:id) })
      .where(sharing: %w(hierarchy descendants))
  end

  def shared_versions_by_hierarchy
    rolled_up_versions
      .where(sharing: 'hierarchy')
  end

  def shared_versions_by_system
    shared_versions_base_scope
      .merge(Project.active)
      .where(sharing: 'system')
  end

  def shared_versions_base_scope
    Version
      .includes(:project)
      .references(:projects)
  end
end

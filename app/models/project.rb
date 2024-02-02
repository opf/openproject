#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Project < ApplicationRecord
  extend FriendlyId

  include Projects::Storage
  include Projects::Activity
  include Projects::Hierarchy
  include Projects::AncestorsFromRoot
  include ::Scopes::Scoped

  # Maximum length for project identifiers
  IDENTIFIER_MAX_LENGTH = 100

  # reserved identifiers
  RESERVED_IDENTIFIERS = %w(new menu).freeze

  has_many :members, -> {
    # TODO: check whether this should
    # remain to be limited to User only
    includes(:principal, :roles)
      .merge(Principal.not_locked.user)
      .references(:principal, :roles)
  }

  has_many :memberships, class_name: 'Member'
  has_many :member_principals,
           -> { not_locked },
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
  has_many :queries, dependent: :destroy
  has_many :news, -> { includes(:author) }, dependent: :destroy
  has_many :categories, -> { order("#{Category.table_name}.name") }, dependent: :delete_all
  has_many :forums, -> { order('position ASC') }, dependent: :destroy
  has_one :repository, dependent: :destroy
  has_many :changesets, through: :repository
  has_one :wiki, dependent: :destroy
  # Custom field for the project's work_packages
  has_and_belongs_to_many :work_package_custom_fields,
                          -> { order("#{CustomField.table_name}.position") },
                          join_table: :custom_fields_projects,
                          association_foreign_key: 'custom_field_id'
  has_many :budgets, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :project_storages, dependent: :destroy, class_name: 'Storages::ProjectStorage'
  has_many :storages, through: :project_storages

  acts_as_customizable
  acts_as_searchable columns: %W(#{table_name}.name #{table_name}.identifier #{table_name}.description),
                     date_column: "#{table_name}.created_at",
                     project_key: 'id',
                     permission: nil

  acts_as_journalized

  # Necessary for acts_as_searchable which depends on the event_datetime method for sorting
  acts_as_event title: Proc.new { |o| "#{Project.model_name.human}: #{o.name}" },
                url: Proc.new { |o| { controller: 'overviews/overviews', action: 'show', project_id: o } },
                author: nil,
                datetime: :created_at

  register_journal_formatted_fields(:active_status, 'active')
  register_journal_formatted_fields(:template, 'templated')
  register_journal_formatted_fields(:plaintext, 'identifier')
  register_journal_formatted_fields(:plaintext, 'name')
  register_journal_formatted_fields(:diff, 'status_explanation')
  register_journal_formatted_fields(:diff, 'description')
  register_journal_formatted_fields(:project_status_code, 'status_code')
  register_journal_formatted_fields(:visibility, 'public')
  register_journal_formatted_fields(:subproject_named_association, 'parent_id')
  register_journal_formatted_fields(:custom_field, /custom_fields_\d+/)

  has_paper_trail

  validates :name,
            presence: true,
            length: { maximum: 255 }

  before_validation :remove_white_spaces_from_project_name

  # TODO: we temporarily disable this validation because it leads to failed tests
  # it implicitly assumes a db:seed-created standard type to be present and currently
  # neither development nor deployment setups are prepared for this
  # validates_presence_of :types

  acts_as_url :name,
              url_attribute: :identifier,
              sync_url: false, # Don't update identifier when name changes
              only_when_blank: true, # Only generate when identifier not set
              limit: IDENTIFIER_MAX_LENGTH,
              blacklist: RESERVED_IDENTIFIERS,
              adapter: OpenProject::ActsAsUrl::Adapter::OpActiveRecord # use a custom adapter able to handle edge cases

  validates :identifier,
            presence: true,
            uniqueness: { case_sensitive: true },
            length: { maximum: IDENTIFIER_MAX_LENGTH },
            exclusion: RESERVED_IDENTIFIERS,
            if: ->(p) { p.persisted? || p.identifier.present? }

  # Contains only a-z, 0-9, dashes and underscores but cannot consist of numbers only as it would clash with the id.
  validates :identifier,
            format: { with: /\A(?!^\d+\z)[a-z0-9\-_]+\z/ },
            if: ->(p) { p.identifier_changed? && p.identifier.present? }

  validates_associated :repository, :wiki

  friendly_id :identifier, use: :finders

  scopes :allowed_to,
         :visible

  scope :has_module, ->(mod) {
    where(["#{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name=?)", mod.to_s])
  }
  scope :public_projects, -> { where(public: true) }
  scope :with_visible_work_packages, ->(user = User.current) do
    where(id: WorkPackage.visible(user).select(:project_id)).or(allowed_to(user, :view_work_packages))
  end
  scope :newest, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }
  scope :archived, -> { where(active: false) }
  scope :with_member, ->(user = User.current) { where(id: user.memberships.select(:project_id)) }
  scope :without_member, ->(user = User.current) { where.not(id: user.memberships.select(:project_id)) }

  scopes :activated_time_activity,
         :visible_with_activated_time_activity

  enum status_code: {
    on_track: 0,
    at_risk: 1,
    off_track: 2,
    not_started: 3,
    finished: 4,
    discontinued: 5
  }

  def visible?(user = User.current)
    active? && (public? || user.admin? || user.access_to?(self))
  end

  def archived?
    !active?
  end

  def being_archived?
    (active == false) && (active_was == true)
  end

  def copy_allowed?
    User.current.allowed_in_project?(:copy_projects, self)
  end

  def self.selectable_projects
    Project.visible.select { |p| User.current.member_of? p }.sort_by(&:to_s)
  end

  # Returns a :conditions SQL string that can be used to find the issues associated with this project.
  #
  # Examples:
  #   project.project_condition(true)  => "(projects.id = 1 OR (projects.lft > 1 AND projects.rgt < 10))"
  #   project.project_condition(false) => "projects.id = 1"
  def project_condition(with_subprojects)
    projects_table = Project.arel_table

    stmt = projects_table[:id].eq(id)
    if with_subprojects && has_subprojects?
      stmt = stmt.or(projects_table[:lft].gt(lft).and(projects_table[:rgt].lt(rgt)))
    end
    stmt
  end

  def has_subprojects?
    !leaf?
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
      versions.where(status: %w(open locked)).find_each do |version|
        if version.completed?
          version.update_attribute(:status, 'closed')
        end
      end
    end
  end

  # Returns a scope of the Versions on subprojects
  def rolled_up_versions
    Version.rolled_up(self)
  end

  # Returns a scope of the Versions used by the project
  def shared_versions
    Version.shared_with(self)
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
  #
  # For custom fields configured with "Allow non-open versions" this can be called
  # with only_open: false, in which case locked and closed versions are returned as well.
  def assignable_versions(only_open: true)
    if only_open
      @assignable_versions ||= shared_versions.references(:project).with_status_open.order_by_semver_name.to_a
    else
      @assignable_versions_including_non_open ||= shared_versions.references(:project).order_by_semver_name.to_a
    end
  end

  # Returns an AR scope of all custom fields enabled for project's work packages
  # (explicitly associated custom fields and custom fields enabled for all projects)
  def all_work_package_custom_fields
    WorkPackageCustomField
      .for_all
      .or(WorkPackageCustomField.where(id: work_package_custom_fields))
  end

  def project
    self
  end

  def <=>(other)
    name.downcase <=> other.name.downcase
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
    if module_names.is_a?(Array)
      module_names = module_names.map(&:to_s).compact_blank
      self.enabled_modules = module_names.map do |name|
        enabled_modules.detect do |mod|
          mod.name == name
        end || EnabledModule.new(name:)
      end
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

  # Returns an array of active subprojects.
  def active_subprojects
    project.descendants.where(active: true)
  end

  class << self
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
      result = []

      projects.sort_by(&:lft).each do |project|
        while ancestors.any? && !project.is_descendant_of?(ancestors.last[:project])
          # before we pop back one level, we sort the child projects by name
          ancestors.last[:children] = sort_by_name(ancestors.last[:children])
          ancestors.pop
        end

        current_hierarchy = { project:, children: [] }
        current_tree = ancestors.any? ? ancestors.last[:children] : result

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

    def project_tree_from_hierarchy(projects_hierarchy, level, &)
      projects_hierarchy.each do |hierarchy|
        project = hierarchy[:project]
        children = hierarchy[:children]
        yield project, level
        # recursively show children
        project_tree_from_hierarchy(children, level + 1, &) if children.any?
      end
    end

    # Yields the given block for each project with its level in the tree
    def project_tree(projects, &)
      projects_hierarchy = build_projects_hierarchy(projects)
      project_tree_from_hierarchy(projects_hierarchy, 0, &)
    end

    private

    def sort_by_name(project_hashes)
      project_hashes.sort_by { |h| h[:project].name&.downcase }
    end
  end

  def allowed_permissions
    @allowed_permissions ||=
      begin
        names = enabled_modules.loaded? ? enabled_module_names : enabled_modules.pluck(:name)

        OpenProject::AccessControl.modules_permissions(names).map(&:name)
      end
  end

  def allowed_actions
    @allowed_actions ||= allowed_permissions.flat_map do |permission|
      OpenProject::AccessControl.allowed_actions(permission)
    end
  end

  def remove_white_spaces_from_project_name
    self.name = name.squish unless name.nil?
  end
end

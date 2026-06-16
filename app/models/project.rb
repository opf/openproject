# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
  include Projects::Activity
  include Projects::AncestorsFromRoot
  include Projects::CustomFields
  include Projects::Hierarchy
  include Projects::Storage
  include Projects::Types
  include Projects::Versions
  include Projects::WorkPackageCustomFields
  include Projects::CreationWizard
  include Projects::Identifier
  include Projects::SemanticIdentifier

  include ::Scopes::Scoped

  enum :workspace_type, {
    project: "project",
    program: "program",
    portfolio: "portfolio"
  }, validate: true

  ALLOWED_PARENT_WORKSPACE_TYPES = {
    project: %i[portfolio program project],
    program: %i[portfolio],
    portfolio: %i[]
  }.with_indifferent_access

  has_many :members, -> {
    # TODO: check whether this should
    # remain to be limited to User only
    includes(:principal, :roles)
      .merge(Principal.not_locked.user)
      .references(:principal, :roles)
  }

  has_many :memberships, class_name: "Member"
  has_many :member_principals,
           -> { not_locked },
           class_name: "Member"
  has_many :users, through: :members, source: :principal
  has_many :principals, through: :member_principals, source: :principal
  has_many :calculated_value_errors, dependent: :delete_all, as: :customized

  has_many :enabled_modules, dependent: :delete_all, after_remove: :module_disabled
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
  has_many :cost_types_projects, dependent: :delete_all
  has_many :cost_types, through: :cost_types_projects
  has_many :queries, dependent: :destroy
  has_many :news, -> { includes(:author) }, dependent: :destroy
  has_many :categories, -> { order("#{Category.table_name}.name") }, dependent: :delete_all
  has_many :forums, -> { order("position ASC") }, dependent: :destroy
  has_one :repository, dependent: :destroy
  has_many :changesets, through: :repository
  has_one :wiki, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :project_storages, dependent: :destroy, class_name: "Storages::ProjectStorage"
  has_many :storages, through: :project_storages
  has_many :phases, class_name: "Project::Phase", dependent: :destroy
  has_many :available_phases,
           -> { visible.order_by_position },
           class_name: "Project::Phase",
           inverse_of: :project

  has_many :recurring_meetings, dependent: :destroy

  belongs_to :template, class_name: "Project", optional: true

  has_many :templated_projects,
           class_name: "Project",
           foreign_key: "template_id",
           inverse_of: :template,
           dependent: nil

  has_many :subproject_template_assignments,
           dependent: :delete_all

  accepts_nested_attributes_for :available_phases
  validates_associated :available_phases, on: :saving_phases

  store_attribute :settings, :deactivate_work_package_attachments, :boolean
  store_attribute :settings, :enabled_internal_comments, :boolean
  store_attribute :settings, :excluded_role_ids_on_copy, :json, default: []

  acts_as_favoritable

  acts_as_customizable validate_on: :saving_custom_fields, comments: true, admin_only_allowed: true
  # extended in Projects::CustomFields in order to support sections
  # and project-level activation of custom fields

  acts_as_searchable columns: %W(#{table_name}.name #{table_name}.identifier #{table_name}.description),
                     date_column: "#{table_name}.created_at",
                     project_key: "id",
                     permission: nil

  acts_as_journalized

  # Necessary for acts_as_searchable which depends on the event_datetime method for sorting
  acts_as_event title: Proc.new { |o| "#{Project.model_name.human}: #{o.name}" },
                url: Proc.new { |o| { controller: "overviews/overviews", action: "show", project_id: o } },
                author: nil,
                datetime: :created_at

  register_journal_formatted_fields "active", formatter_key: :active_status
  register_journal_formatted_fields "cause", formatter_key: :cause
  register_journal_formatted_fields "templated", formatter_key: :template
  register_journal_formatted_fields "identifier", "name", formatter_key: :plaintext
  register_journal_formatted_fields "status_explanation", "description", formatter_key: :diff
  register_journal_formatted_fields "status_code", formatter_key: :project_status_code
  register_journal_formatted_fields "public", formatter_key: :visibility
  register_journal_formatted_fields "parent_id", formatter_key: :subproject_named_association
  register_journal_formatted_fields /\Acustom_fields_\d+\z/, formatter_key: :custom_field
  register_journal_formatted_fields /\Acustom_comment_\d+\z/, formatter_key: :custom_comment
  register_journal_formatted_fields /\Aproject_phase_\d+_active\z/, formatter_key: :project_phase_active
  register_journal_formatted_fields /\Aproject_phase_\d+_date_range\z/, formatter_key: :project_phase_dates

  has_paper_trail

  validates :name,
            presence: true,
            length: { maximum: 255 }

  normalizes :name, with: ->(name) { name.squish }

  # TODO: we temporarily disable this validation because it leads to failed tests
  # it implicitly assumes a db:seed-created standard type to be present and currently
  # neither development nor deployment setups are prepared for this
  # validates_presence_of :types

  validates_associated :repository, :wiki

  scopes :activated_in_storage,
         :allowed_to,
         :assignable_parents,
         :available_custom_fields,
         :available_templates,
         :visible,
         :with_settings

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
  scope :workspace_type, ->(workspace_type) { workspace_types.key?(workspace_type) ? where(workspace_type:) : none }
  scope :templated, -> { where(templated: true) }

  scopes :activated_time_activity,
         :visible_with_activated_time_activity,
         :available_cost_types

  enum :status_code, {
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

  def project
    self
  end

  def <=>(other)
    name.downcase <=> other.name.downcase
  end

  def to_s
    name
  end

  def workspace_label
    case workspace_type
    when "program"
      I18n.t("label_program")
    when "portfolio"
      I18n.t("label_portfolio")
    else
      I18n.t("label_project")
    end
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

  def reload(*)
    @allowed_permissions = nil
    @allowed_actions = nil

    super
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

  def module_disabled(disabled_module)
    OpenProject::Notifications.send(
      OpenProject::Events::MODULE_DISABLED, disabled_module:
    )
  end
end

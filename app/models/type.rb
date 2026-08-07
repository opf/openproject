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

class Type < ApplicationRecord
  # Work Package attributes for this type
  # and constraints to specific attributes (by plugins).
  include ::Type::Attributes
  include ::Type::AttributeGroups
  prepend ::Type::ConfigurationLinkable

  include ::Scopes::Scoped

  attribute :patterns, WorkPackageTypes::Patterns::CollectionType.new

  store_attribute :pdf_export_templates_config, :export_templates_disabled, :json
  store_attribute :pdf_export_templates_config, :export_templates_order, :json
  store_attribute :pdf_export_templates_config, :artefact_export_mode, :string

  before_destroy :check_integrity

  belongs_to :color, optional: true, class_name: "Color"

  # The owning project, or nil for a global type.
  belongs_to :project, optional: true

  has_many :work_packages
  # The write target and the eager-loadable association.
  # Reads go through #project_custom_field_type_mappings, which resolves the
  # mappings based on the PROJECT_ATTRIBUTES linking mode.
  has_many :own_project_custom_field_type_mappings,
           class_name: "ProjectCustomFieldTypeMapping",
           dependent: :destroy
  has_many :project_custom_fields, through: :own_project_custom_field_type_mappings,
                                   class_name: "ProjectCustomField"
  # The write target and the eager-loadable association
  # Reads go through #workflows, which resolves workflows based on linking mode
  has_many :own_workflows,
           class_name: "Workflow",
           foreign_key: :type_id,
           inverse_of: :type,
           dependent: :delete_all do
    def copy_from_type(source_type)
      Workflow.copy(source_type, nil, proxy_association.owner, nil)
    end
  end

  # Projects using this type. A project always uses the root, so a variant has none.
  has_many :project_types, dependent: :delete_all
  has_many :projects, through: :project_types

  # Rows naming this type as the resolved variant. Nothing reads them directly; they are how
  # #effective_in_projects finds a variant's projects, which #projects cannot.
  has_many :variant_project_types,
           class_name: "ProjectType",
           foreign_key: :variant_id,
           inverse_of: :variant,
           dependent: :nullify

  has_and_belongs_to_many :custom_fields,
                          class_name: "WorkPackageCustomField",
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          association_foreign_key: "custom_field_id"

  belongs_to :parent, class_name: "Type", optional: true
  has_many :children, class_name: "Type", foreign_key: :parent_id, inverse_of: :parent,
                      dependent: :restrict_with_error

  acts_as_list scope: :parent_id

  # Scoped by owner as well as family: two projects naming their own variant the same
  # is the expected case, not a clash.
  validates :name,
            presence: true,
            uniqueness: { scope: %i[parent_id project_id], case_sensitive: false },
            length: { maximum: 255 }

  validate :parent_is_a_root
  validate :not_own_parent
  validate :cannot_have_children_when_child
  validate :standard_type_stays_root
  validate :parent_frozen_while_used_by_projects
  validate :owned_type_is_a_variant
  validate :owned_type_parent_is_global

  scopes :milestone,
         :with_effective_configuration,
         :with_effective_source

  default_scope { order("position ASC") }

  scope :roots, -> { where(parent_id: nil) }
  scope :variants, -> { where.not(parent_id: nil) }
  scope :global, -> { where(project_id: nil) }
  # A source is a global type, or a variant owned by the same project as the type being
  # configured. A global type's project_id is nil, so this collapses to global-only.
  scope :selectable_as_source_for, ->(type) { where(project_id: [nil, type.project_id]) }
  scope :without_standard, -> { where(is_standard: false).order(:position) }
  scope :default, -> { where(is_default: true) }
  # An owned variant only reaches someone who can see its project. Without this the
  # /api/v3/types/:id and MCP show paths served any variant by id.
  scope :visible, ->(user = User.current) {
    if user.allowed_in_any_project?(:view_work_packages) || user.allowed_in_any_project?(:manage_types)
      global.or(where(project_id: Project.allowed_to(user, :view_work_packages).select(:id)))
    else
      none
    end
  }

  delegate :to_s, to: :name

  # Roots each immediately followed by their own variants. Reads one acts_as_list
  # list at a time on purpose: positions are numbered per family, so no ORDER BY
  # over the flat table can keep a family together.
  def self.in_family_order
    roots.includes(:children).flat_map(&:family)
  end

  # Cannot go through in_family_order: that walks #family, which reads #children and so
  # would surface variants owned by other projects.
  def self.in_family_order_available_in(project)
    global.roots.includes(:children).flat_map { |root| [root, *root.variants_available_in(project)] }
  end

  def <=>(other)
    name <=> other.name
  end

  def self.statuses(types, role: nil, tab: nil) # rubocop:disable Metrics/AbcSize
    workflow_table, status_table = [Workflow, Status].map(&:arel_table)
    old_id_subselect, new_id_subselect = %i[old_status_id new_status_id].map do |foreign_key|
      subquery = workflow_table.project(workflow_table[foreign_key]).where(workflow_table[:type_id].in(types))
      subquery = subquery.where(workflow_table[:role_id].eq(role.id)) if role
      subquery = apply_tab_condition(subquery, workflow_table, tab) if tab
      subquery
    end
    Status.where(status_table[:id].in(old_id_subselect).or(status_table[:id].in(new_id_subselect)))
  end

  def self.apply_tab_condition(subquery, workflow_table, tab)
    case tab
    when "author"
      subquery.where(workflow_table[:author].eq(true))
    when "assignee"
      subquery.where(workflow_table[:assignee].eq(true))
    else
      subquery.where(workflow_table[:author].eq(false).and(workflow_table[:assignee].eq(false)))
    end
  end

  def self.standard_type
    where(is_standard: true).first
  end

  # The roots the given project(s) use. A project uses a root even when it resolves the family
  # to a variant, so a variant is never returned.
  #
  # Resolved as a subquery rather than a join so a root used by several projects yields one row:
  # a join would duplicate it, which the eager load only hid from callers reading records and
  # not from those plucking ids.
  def self.enabled_in(project)
    where(id: ProjectType.where(project_id: project).select(:type_id))
  end

  # Writers use #own_workflows; the flag-off branch also keeps it so an eager-loaded
  # association (see TypesController) stays usable. When variants are on, the effective
  # owner is resolved inside the query, avoiding a separate resolution round-trip.
  def workflows
    return own_workflows unless resolve_aspect_in_sql?

    Workflow.where(Workflow.arel_table[:type_id].in(effective_source_id_ref(Type::ConfigurationLink::WORKFLOWS)))
  end

  # Writers use #own_project_custom_field_type_mappings; the flag-off branch keeps it
  # too. When variants are on, the effective owner is resolved inside the query,
  # avoiding a separate resolution round-trip.
  def project_custom_field_type_mappings
    return own_project_custom_field_type_mappings unless resolve_aspect_in_sql?

    aspect = Type::ConfigurationLink::PROJECT_ATTRIBUTES
    mappings = ProjectCustomFieldTypeMapping.where(
      ProjectCustomFieldTypeMapping.arel_table[:type_id].in(effective_source_id_ref(aspect))
    )
    excluded_ids = excluded_custom_field_ids(aspect)
    return mappings if excluded_ids.empty?

    mappings.where.not(custom_field_id: excluded_ids)
  end

  def statuses(include_default: false, role: nil, tab: nil)
    return Status.none if new_record?

    type_ref = resolve_aspect_in_sql? ? effective_source_id_ref(Type::ConfigurationLink::WORKFLOWS) : [id]
    scope = self.class.statuses(type_ref, role:, tab:)
    include_default ? scope.or(Status.where_default) : scope
  end

  # The projects this type is the member in force for — the inverse of Project#effective_type.
  # A variant's are the projects resolving the family to it; a root's are those using it
  # without resolving a variant.
  #
  # Distinct from #projects, which a variant never appears in: a project uses the root even
  # when the configuration in force is the variant's.
  def effective_in_projects
    Project.where(id: ProjectType.where(variant_id: id)
                                 .or(ProjectType.where(type_id: id, variant_id: nil))
                                 .select(:project_id))
  end

  # A project only shows custom fields its own activation includes, so fields on this type's
  # form have to be activated wherever that form is in force, or the form silently omits them.
  # Load-bearing for variants: a variant never appears in #projects, so nothing else reaches
  # the projects whose form it configures.
  def activate_custom_fields_in_effective_projects!
    return if custom_field_ids.empty?

    effective_in_projects.each do |project|
      project.work_package_custom_field_ids |= custom_field_ids
    end
  end

  def root
    parent || self
  end

  def root_id
    parent_id || id
  end

  def variant?
    parent_id.present?
  end

  def project_owned?
    project_id.present?
  end

  # A variant's acts_as_list position is append order and users cannot reorder
  # variants, so position is not a display order for them; alphabetical is.
  # Every screen that lists a family reads this, so the orders cannot drift.
  def sorted_variants
    children.sort_by { |variant| variant.own_name.downcase }
  end

  # The variants of this root the given project may see: the global ones plus its own.
  def variants_available_in(project)
    sorted_variants.select { |variant| variant.project_id.nil? || variant.project_id == project&.id }
  end

  def family
    [root, *root.sorted_variants]
  end

  def name
    inherited_core_setting(:name)
  end

  def own_name
    self[:name]
  end

  def composite_name
    variant? ? "#{name}: #{own_name}" : name
  end

  # Validate the type's own name, not the root's name as would happen without this for variants
  def read_attribute_for_validation(key)
    key.to_sym == :name ? own_name : super
  end

  # Core settings are inherited from the parent for variants. The variant's
  # own columns are ignored while it has a parent.
  def color
    variant? ? root.color : super
  end

  def color_id
    inherited_core_setting(:color_id)
  end

  # rubocop:disable Naming/PredicatePrefix
  # These override the ActiveRecord attribute readers of the same name, so they
  # must keep the is_ prefix the rest of the code relies on.
  def is_milestone
    inherited_core_setting(:is_milestone)
  end
  alias_method :is_milestone?, :is_milestone

  def is_in_roadmap
    inherited_core_setting(:is_in_roadmap)
  end
  alias_method :is_in_roadmap?, :is_in_roadmap
  # rubocop:enable Naming/PredicatePrefix

  def replacement_pattern_defined_for?(attribute)
    enabled_patterns.key?(attribute)
  end

  def enabled_patterns
    patterns.all_enabled
  end

  def pdf_export_templates
    @pdf_export_templates ||= ::Type::PdfExportTemplates.new(self)
  end

  # The store_attribute :default is not returned when the JSON key is present
  # but nil, so mirror the getter-override pattern used elsewhere (see
  # Projects::CreationWizard) to guarantee a value.
  def artefact_export_mode
    super.presence || Type::ArtefactExport::DEFAULT
  end

  def artefact_export_enabled?
    artefact_export_mode != Type::ArtefactExport::OFF
  end

  private

  def inherited_core_setting(name)
    root.read_attribute(name)
  end

  def check_integrity
    throw :abort if is_standard?
    throw :abort if WorkPackage.exists?(type_id: id)

    true
  end

  def parent_is_a_root
    return if parent.nil?

    errors.add(:parent, :must_be_a_root) if parent.parent_id.present?
  end

  def not_own_parent
    errors.add(:parent, :cannot_be_self) if parent_id.present? && parent_id == id
  end

  def cannot_have_children_when_child
    return if parent_id.blank? || new_record?

    errors.add(:parent, :cannot_have_children) if children.exists?
  end

  def standard_type_stays_root
    errors.add(:parent, :standard_type_must_be_root) if is_standard? && parent_id.present?
  end

  # Owning a root would be owning a global type, which :manage_project_variants
  # deliberately does not grant.
  def owned_type_is_a_variant
    return if project_id.blank? || parent_id.present?

    errors.add(:project, :must_own_a_variant)
  end

  def owned_type_parent_is_global
    return if project_id.blank? || parent.nil? || parent.project_id.nil?

    errors.add(:parent, :must_be_global)
  end

  # Re-parenting moves a type into another family or out of one, which would leave every
  # project_types row referencing it either using a type that is no longer a root, or
  # resolving to a variant of a different family than the row uses. Neither row gets
  # revalidated, so the only place to catch it is here.
  def parent_frozen_while_used_by_projects
    return unless parent_id_changed? && persisted?
    return unless ProjectType.where(type_id: id).or(ProjectType.where(variant_id: id)).exists?

    errors.add(:parent, :cannot_change_while_used_by_projects)
  end
end

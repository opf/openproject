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

# One configuration of a work package type: the form, workflows, subject patterns, PDF export
# settings and project attributes that apply where this variant is being used.
#
# Every type has exactly one base variant (+is_default_variant+, no name) holding the
# configuration it uses as a default.
# The active variant is applied per project (see ProjectType#variant).
class TypeVariant < ApplicationRecord
  ASPECTS = [
    PDF_EXPORT = "pdf_export",
    DEFAULTS = "defaults",
    WORKFLOWS = "workflows",
    FORM_CONFIGURATION = "form_configuration",
    PROJECT_ATTRIBUTES = "project_attributes"
  ].freeze

  # The aspects a variant can reduce fields in
  EXCLUDABLE_ASPECTS = [FORM_CONFIGURATION, PROJECT_ATTRIBUTES].freeze

  include ::Scopes::Scoped
  include ::Type::Attributes
  include ::Type::AttributeGroups
  prepend ::TypeVariant::ConfigurationLinkable

  attribute :patterns, WorkPackageTypes::Patterns::CollectionType.new

  store_attribute :pdf_export_templates_config, :export_templates_disabled, :json
  store_attribute :pdf_export_templates_config, :export_templates_order, :json
  store_attribute :pdf_export_templates_config, :artefact_export_mode, :string
  store_attribute :pdf_export_templates_config, :export_templates_settings, :json

  belongs_to :type

  # The project owning this variant, or nil for a variant every project may use.
  belongs_to :project, optional: true

  # Which workflows we are defining ourselves
  has_many :own_workflows,
           class_name: "Workflow",
           foreign_key: :type_variant_id,
           inverse_of: :type_variant,
           dependent: :delete_all do
    def copy_from_variant(source_variant)
      Workflow.copy(source_variant, nil, proxy_association.owner, nil)
    end
  end

  # Which project custom fields we define ourselves
  has_many :own_project_custom_field_type_mappings,
           class_name: "ProjectCustomFieldTypeMapping",
           inverse_of: :type_variant,
           dependent: :destroy
  has_many :project_custom_fields, through: :own_project_custom_field_type_mappings,
                                   class_name: "ProjectCustomField"

  has_and_belongs_to_many :custom_fields, # rubocop:disable Rails/HasAndBelongsToMany
                          class_name: "WorkPackageCustomField",
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          association_foreign_key: "custom_field_id"

  # The projects this variant is in use
  # autosave must be turned off: If we autosaved here, the insert would only set variant_id and leave type_id NULL.
  has_many :project_types, foreign_key: :variant_id, inverse_of: :variant, dependent: :restrict_with_error,
                           autosave: false
  has_many :projects, through: :project_types

  validates :variant_name, length: { maximum: 255 }
  validates :variant_name,
            presence: true,
            uniqueness: { scope: %i[type_id project_id], case_sensitive: false },
            unless: :is_default_variant?
  validate :base_variant_has_no_name
  validate :only_one_variant_enabled_in_new_projects
  validate :base_variant_is_never_owned
  validate :owned_variant_is_never_enabled_in_new_projects

  scopes :switch_targets, :with_effective_configuration, :with_effective_source

  scope :enabled_in_new_projects, -> { where(enabled_in_new_projects: true) }

  scope :default_variant, -> { where(is_default_variant: true) }
  scope :non_default_variants, -> { where(is_default_variant: false) }

  scope :global, -> { where(project_id: nil) }
  scope :project_owned, -> { where.not(project_id: nil) }
  scope :owned_by, ->(project) { where(project:) }
  scope :available_in, ->(project) { where(project: [nil, project]) }

  # Base variants first, then the named ones alphabetically. Named variants have no user defined order
  scope :in_display_order, -> { order(is_default_variant: :desc, variant_name: :asc) }

  scope :with_name_like, ->(query) {
    where("variant_name ILIKE :query", query: "%#{sanitize_sql_like(query.to_s.strip)}%")
  }

  delegate :name, :color, :color_id, :is_milestone, :is_milestone?, :is_in_roadmap, :is_in_roadmap?,
           to: :type

  def self.statuses(variants, role: nil, tab: nil) # rubocop:disable Metrics/AbcSize
    workflow_table, status_table = [Workflow, Status].map(&:arel_table)
    old_id_subselect, new_id_subselect = %i[old_status_id new_status_id].map do |foreign_key|
      subquery = workflow_table.project(workflow_table[foreign_key])
                               .where(workflow_table[:type_variant_id].in(variants))
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

  # The base configuration every type has, as opposed to one of its named variants.
  def default? = is_default_variant?

  # What users call this configuration: a named variant by its own name, the base one by the
  # type it configures.
  def display_name
    variant_name.presence || type.name
  end

  # How the admin routes address this variant. The base one is implied by its type, so naming
  # it would make every type-level URL carry a redundant id.
  def project_owned? = project_id.present?

  def path_args
    args = is_default_variant? ? { type_id: } : { type_id:, variant_id: id }
    project_id.nil? ? args : args.merge(in_project_id: project)
  end

  # Full variant name, e.g., "Bug: Hardware"
  def composite_name
    is_default_variant? ? type.name : "#{type.name}: #{variant_name}"
  end

  def work_packages
    WorkPackage.where(type_id:, project_id: project_types.select(:project_id))
  end

  def migration_targets
    siblings = self.class.where(type_id:).where.not(id:)
    owners = projects.distinct.pluck(:id)

    owners.one? ? siblings.available_in(owners.first) : siblings.global
  end

  def workflows
    return own_workflows unless resolve_aspect_in_sql?

    Workflow.where(Workflow.arel_table[:type_variant_id].in(effective_source_id_ref(WORKFLOWS)))
  end

  def project_custom_field_type_mappings
    return own_project_custom_field_type_mappings unless resolve_aspect_in_sql?

    mappings = ProjectCustomFieldTypeMapping.where(
      ProjectCustomFieldTypeMapping.arel_table[:type_variant_id].in(effective_source_id_ref(PROJECT_ATTRIBUTES))
    )
    excluded_ids = excluded_custom_field_ids(PROJECT_ATTRIBUTES)
    return mappings if excluded_ids.empty?

    mappings.where.not(custom_field_id: excluded_ids)
  end

  def statuses(include_default: false, role: nil, tab: nil)
    return Status.none if new_record?

    variant_ref = resolve_aspect_in_sql? ? effective_source_id_ref(WORKFLOWS) : [id]
    scope = self.class.statuses(variant_ref, role:, tab:)
    include_default ? scope.or(Status.where_default) : scope
  end

  # A project only shows custom fields its own activation includes, so fields on this
  # variant's form have to be activated wherever that form is in force, or the form silently
  # omits them.
  # TODO: This needs to be removed in the custom field form migration
  def activate_custom_fields_in_effective_projects!
    return if custom_field_ids.empty?

    projects.each do |project|
      project.work_package_custom_field_ids |= custom_field_ids
    end
  end

  def replacement_pattern_defined_for?(attribute)
    enabled_patterns.key?(attribute)
  end

  def enabled_patterns
    patterns.all_enabled
  end

  def pdf_export_templates
    @pdf_export_templates ||= ::Type::PdfExportTemplates.new(self)
  end

  def artefact_export_mode
    super.presence || Type::ArtefactExport::DEFAULT
  end

  def artefact_export_enabled?
    artefact_export_mode != Type::ArtefactExport::OFF
  end

  private

  def base_variant_has_no_name
    return if is_default_variant? == variant_name.nil?

    errors.add(:variant_name, is_default_variant? ? :must_be_blank : :blank)
  end

  # A new project applies one configuration per type, so only one of a type's variants may be
  # the one it starts with. Mirrors index_type_variants_one_new_project_default_per_type.
  def only_one_variant_enabled_in_new_projects
    return unless enabled_in_new_projects?

    siblings = self.class.where(type_id:).enabled_in_new_projects
    siblings = siblings.where.not(id:) if persisted?

    errors.add(:enabled_in_new_projects, :taken) if siblings.exists?
  end

  # A new project would start on a configuration only the owning project can see.
  def owned_variant_is_never_enabled_in_new_projects
    return unless enabled_in_new_projects? && project_id.present?

    errors.add(:enabled_in_new_projects, :not_available_to_project_owned_variant)
  end

  # A type's own configuration belongs to the type, so no single project may own it.
  def base_variant_is_never_owned
    return unless is_default_variant? && project_id.present?

    errors.add(:project, :present)
  end
end

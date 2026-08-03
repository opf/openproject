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

  has_and_belongs_to_many :projects

  has_and_belongs_to_many :custom_fields,
                          class_name: "WorkPackageCustomField",
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          association_foreign_key: "custom_field_id"

  belongs_to :parent, class_name: "Type", optional: true
  has_many :children, class_name: "Type", foreign_key: :parent_id, inverse_of: :parent,
                      dependent: :restrict_with_error

  acts_as_list scope: :parent_id

  validates :name,
            presence: true,
            uniqueness: { scope: :parent_id, case_sensitive: false },
            length: { maximum: 255 }

  validate :parent_is_a_root
  validate :not_own_parent
  validate :cannot_have_children_when_child
  validate :standard_type_stays_root
  validate :parent_frozen_with_work_packages

  scopes :milestone,
         :with_effective_configuration,
         :with_effective_source

  default_scope { order("position ASC") }

  scope :roots, -> { where(parent_id: nil) }
  scope :variants, -> { where.not(parent_id: nil) }
  # All types are global until project-owned variants exist; this is the seam the
  # configuration source picker and contract scope against (see FND-103 :manage_type_variants).
  scope :global, -> { all }
  scope :without_standard, -> { where(is_standard: false).order(:position) }
  scope :default, -> { where(is_default: true) }
  scope :visible, ->(user = User.current) {
    if user.allowed_in_any_project?(:view_work_packages) || user.allowed_in_any_project?(:manage_types)
      all
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

  # Ids of every member of the families the given ids belong to. Variants are
  # transparent to users, so a filter naming one member has to match them all.
  def self.family_ids(ids)
    root_ids = where(id: ids).pluck(Arel.sql("COALESCE(parent_id, id)")).uniq

    where(id: root_ids).or(where(parent_id: root_ids)).pluck(:id)
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

  def self.enabled_in(project)
    includes(:projects).where(projects: { id: project })
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

  def enabled_in?(object)
    object.types.include?(self)
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

  # A variant's acts_as_list position is append order and users cannot reorder
  # variants, so position is not a display order for them; alphabetical is.
  # Every screen that lists a family reads this, so the orders cannot drift.
  def sorted_variants
    children.sort_by { |variant| variant.own_name.downcase }
  end

  def family
    [root, *root.sorted_variants]
  end

  def name
    inherited_core_setting(:name)
  end

  def own_name
    read_attribute(:name)
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

  def parent_frozen_with_work_packages
    return unless parent_id_changed? && persisted?

    errors.add(:parent, :cannot_change_with_work_packages) if WorkPackage.exists?(type_id: id)
  end
end

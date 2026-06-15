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

  include ::Scopes::Scoped

  attribute :patterns, WorkPackageTypes::Patterns::CollectionType.new

  store_attribute :pdf_export_templates_config, :export_templates_disabled, :json
  store_attribute :pdf_export_templates_config, :export_templates_order, :json

  before_destroy :check_integrity

  belongs_to :color, optional: true, class_name: "Color"

  has_many :work_packages
  has_many :project_custom_field_type_mappings, dependent: :destroy
  has_many :project_custom_fields, through: :project_custom_field_type_mappings,
                                   class_name: "ProjectCustomField"
  has_many :workflows, dependent: :delete_all do
    def copy_from_type(source_type)
      Workflow.copy(source_type, nil, proxy_association.owner, nil)
    end
  end

  has_and_belongs_to_many :projects

  has_and_belongs_to_many :custom_fields,
                          class_name: "WorkPackageCustomField",
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          association_foreign_key: "custom_field_id"

  acts_as_list

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 255 }

  scopes :milestone

  default_scope { order("position ASC") }

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

  def statuses(include_default: false, role: nil, tab: nil)
    if new_record?
      Status.none
    elsif include_default
      self.class.statuses([id], role:, tab:).or(Status.where_default)
    else
      self.class.statuses([id], role:, tab:)
    end
  end

  def enabled_in?(object)
    object.types.include?(self)
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

  private

  def check_integrity
    throw :abort if is_standard?
    throw :abort if WorkPackage.exists?(type_id: id)

    true
  end
end

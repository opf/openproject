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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackageCustomField < CustomField
  # A field reaches a project when the variant that project applies shows it. An archived project
  # is no reach, which is the same answer CustomFields::DetailsComponent gives.
  def self.project_counts
    memberships = FormConfigurationAttribute.table_name
    form_join, form_configuration_id, excluded =
      TypeVariant.form_configuration_join("project_types.variant_id")
    exclusion = TypeVariant.excluded_custom_field_condition("#{memberships}.custom_field_id", excluded)

    ProjectType
      .joins(form_join)
      .joins(Arel.sql("JOIN #{memberships} ON #{memberships}.form_configuration_id = #{form_configuration_id} " \
                      "AND #{memberships}.custom_field_id IS NOT NULL " \
                      "AND #{memberships}.form_configuration_group_id IS NOT NULL AND #{exclusion}"))
      .where(project_id: Project.active.select(:id))
      .group("#{memberships}.custom_field_id")
      .distinct
      .count(:project_id)
  end

  has_many :form_configuration_memberships, -> { active },
           class_name: "FormConfigurationAttribute",
           foreign_key: :custom_field_id,
           inverse_of: :custom_field,
           dependent: nil
  has_many :form_configurations, -> { distinct }, through: :form_configuration_memberships
  has_many :type_variants, through: :form_configurations
  has_many :work_packages,
           through: :custom_values,
           source: :customized,
           source_type: "WorkPackage"

  scopes :visible,
         :on_visible_type_and_project

  scope :usable_as_automation, -> {
    where.not(field_format: %w[hierarchy weighted_item_list])
         .order(:name)
  }

  def self.summable
    where(field_format: %w[int float])
  end

  def summable?
    %w[int float].include?(field_format)
  end

  def visible?(usr = User.current, project: nil)
    self.class.visible(usr, project:).exists?(id: id)
  end

  def type_name
    :label_work_package_plural
  end

  def to_s
    "#{name} #{field_format}"
  end
end

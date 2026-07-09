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

# @deprecated Bulk-assigning the full set of type ids is being replaced by the
#   granular Projects::Types::AddService, RemoveService and SwitchSubtypeService.
#   This service remains only until the project settings UI is migrated to them.
class UpdateProjectsTypesService < BaseProjectService
  def call(type_ids)
    type_ids = standard_types if type_ids.blank?

    if types_missing?(type_ids)
      project.errors.add(:types,
                         :in_use_by_work_packages,
                         types: missing_types(type_ids).map(&:name).join(", "))
      false
    elsif any_type_is_a_subtype?(type_ids) && !OpenProject::FeatureDecisions.subtypes_active?
      project.errors.add(:types, :cannot_assign_subtypes_yet)
      false
    elsif multiple_subtypes_of_parent?(type_ids)
      project.errors.add(:types, :cannot_assign_multiple_subtypes_of_parent)
      false
    elsif subtype_and_parent_enabled?(type_ids)
      project.errors.add(:types, :cannot_assign_subtype_and_parent)
      false
    else
      update_project_types(type_ids)

      true
    end
  end

  protected

  def standard_types
    type = ::Type.standard_type
    if type.nil?
      []
    else
      [type.id]
    end
  end

  def any_type_is_a_subtype?(type_ids)
    Type.where(id: type_ids).where.not(parent_id: nil).exists?
  end

  def multiple_subtypes_of_parent?(type_ids)
    Type
      .reorder(nil)
      .where(id: type_ids)
      .where.not(parent_id: nil)
      .group(:parent_id)
      .having("COUNT(*) > 1")
      .exists?
  end

  def subtype_and_parent_enabled?(type_ids)
    parent_ids = Type.where(id: type_ids).pluck(:parent_id).compact

    parent_ids.intersect?(type_ids.map(&:to_i))
  end

  def types_missing?(type_ids)
    !missing_types(type_ids).empty?
  end

  def missing_types(type_ids)
    types_used_by_work_packages.select { |t| type_ids.exclude?(t.id) }
  end

  def types_used_by_work_packages
    @types_used_by_work_packages ||= project.types_used_by_work_packages
  end

  def update_project_types(type_ids)
    new_types_to_add = type_ids - project.type_ids
    project.type_ids = type_ids
    project.work_package_custom_field_ids |= WorkPackageCustomField.joins(:types).where(types: { id: new_types_to_add }).ids
  end
end

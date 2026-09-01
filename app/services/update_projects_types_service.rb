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
#   granular Projects::Types::AddService, RemoveService and SwitchVariantService.
#   This service remains only until the project settings UI is migrated to them.
class UpdateProjectsTypesService < BaseProjectService
  # The bulk form names types, never variants, so a project keeps whichever variant it
  # already applies for a type it keeps and gets the base variant for one it gains.
  def call(type_ids)
    type_ids = Array(type_ids)

    if types_missing?(type_ids)
      project.errors.add(:types,
                         :in_use_by_work_packages,
                         types: missing_types(type_ids).map(&:name).join(", "))
      false
    else
      update_project_types(type_ids)

      true
    end
  end

  protected

  def types_missing?(type_ids)
    !missing_types(type_ids).empty?
  end

  def missing_types(type_ids)
    types_used_by_work_packages.select { |t| type_ids.exclude?(t.id) }
  end

  def types_used_by_work_packages
    @types_used_by_work_packages ||= project.types_used_by_work_packages
  end

  def update_project_types(type_ids) # rubocop:disable Metrics/AbcSize
    requested_ids = type_ids.map(&:to_i)
    added_ids = requested_ids - project.project_types.pluck(:type_id)

    project.project_types.where.not(type_id: requested_ids).destroy_all
    ::TypeVariant.default_variant.where(type_id: added_ids).find_each do |variant|
      project.project_types.create!(type_id: variant.type_id, variant:)
    end

    project.reload
    project.work_package_custom_field_ids |= custom_field_ids_of(added_ids)
  end

  # TypeVariant#custom_fields resolves the form configuration link, so a variant inheriting
  # its configuration contributes the fields it actually shows rather than the none it owns.
  # A type gained here runs its base variant, which is what the project resolves to.
  def custom_field_ids_of(type_ids)
    ::TypeVariant.default_variant.where(type_id: type_ids).flat_map { |variant| variant.custom_fields.ids }.uniq
  end
end

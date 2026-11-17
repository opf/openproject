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

module Planner
  # The variant is found through the field, so renaming either in the administration keeps the
  # Planner working. The owners' role is remembered in the module's settings.
  class SetupService
    Setup = Data.define(:variant, :role)

    # Without "Add work packages", core keeps "My work" out of every create and move picker, so to-dos
    # are only added in My planner (see CreateTaskContract).
    ROLE_PERMISSIONS = %i[
      view_project
      view_work_packages
      edit_work_packages
      change_work_package_status
      delete_work_packages
      manage_work_package_relations
      add_work_package_comments
      edit_own_work_package_comments
      add_work_package_attachments
      view_work_package_watchers
      export_work_packages
    ].freeze

    def call
      OpenProject::Mutex.with_advisory_lock(TypeVariant, "planner_setup") do
        # Every user's planner shares these, so they are named in the instance's language rather than
        # in the language of whoever happens to open My planner first.
        I18n.with_locale(Setting.default_language) do
          variant = existing_variant
          (variant ? ServiceResult.success(result: variant) : create_variant)
            .map { Setup.new(variant: it, role: role(it)) }
        end
      end
    end

    private

    def day_part_field
      @day_part_field ||= WorkPackageCustomField.for_semantic_key(:day_part) || create_day_part_field
    end

    def existing_variant
      TypeVariant
        .global
        .non_default_variants
        .joins(form_configuration: :custom_fields)
        .find_by(custom_fields: { id: day_part_field.id })
    end

    def create_variant
      type = Type.where(is_milestone: false).order(:position).first

      create_form(type).bind do |form|
        WorkPackageTypes::CreateVariantService
          .new(user: User.system, type:)
          .call(variant_name: I18n.t("planner.variant_name"), form_configuration_id: form.id)
      end
    end

    def create_form(type)
      FormConfigurations::CreateService
        .new(user: User.system)
        .call(name: I18n.t("planner.form_name"), copy_from_id: type.default_variant.form_configuration_id)
        .on_success { |call| call.result.custom_field_ids = call.result.custom_field_ids + [day_part_field.id] }
    end

    def role(variant)
      ProjectRole.find_by(id: Setting.plugin_openproject_planner["role_id"]) || create_role(variant)
    end

    def create_role(variant)
      ProjectRole.create!(name: available_name(Role, I18n.t("planner.role_name")), permissions: ROLE_PERMISSIONS)
        .tap do |role|
          copy_workflow(variant, role)
          Setting.plugin_openproject_planner = Setting.plugin_openproject_planner.merge("role_id" => role.id)
        end
    end

    # Status transitions are per role, so the owners can move their to-dos between the same statuses as
    # project creators.
    def copy_workflow(variant, role)
      source = ProjectRole.in_new_project
      Workflows::StatusTransition.copy(variant.workflow, source, [variant.workflow], [role]) if source
    end

    def create_day_part_field
      WorkPackageCustomField.create!(
        name: available_name(WorkPackageCustomField, I18n.t("planner.day_part.name")),
        field_format: "list",
        possible_values: DayPartField::DAY_PARTS.map { I18n.t("planner.day_part.#{it}") },
        semantic_key: :day_part
      )
    end

    # Names are unique, and the instance may already use ours, such as a "Day part" field of its own.
    def available_name(model, name)
      model.exists?(["LOWER(name) = LOWER(?)", name]) ? "#{name} (#{I18n.t(:label_planner)})" : name
    end
  end
end

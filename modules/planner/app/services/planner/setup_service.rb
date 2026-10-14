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
  # Planner working.
  class SetupService
    def call
      OpenProject::Mutex.with_advisory_lock(TypeVariant, "planner_setup") do
        variant = existing_variant
        variant ? ServiceResult.success(result: variant) : create_variant
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

    def create_day_part_field
      WorkPackageCustomField.create!(
        name: day_part_field_name,
        field_format: "list",
        possible_values: DayPartField::DAY_PARTS.map { I18n.t("planner.day_part.#{it}") },
        semantic_key: :day_part
      )
    end

    # Field names are unique, and the instance may already have a "Day part" field of its own.
    def day_part_field_name
      name = I18n.t("planner.day_part.name")
      return name unless WorkPackageCustomField.exists?(["LOWER(name) = LOWER(?)", name])

      "#{name} (#{I18n.t(:label_planner)})"
    end
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Projects::ActsAsCustomizablePatches
  extend ActiveSupport::Concern

  attr_accessor :limit_custom_fields_validation_to_section_id

  # attr_accessor :limit_custom_fields_validation_to_field_id
  # not needed for now, but might be relevant if we want to have edit dialogs just for one custom field

  included do
    has_many :project_custom_field_project_mappings, class_name: 'ProjectCustomFieldProjectMapping', foreign_key: :project_id,
                                                     dependent: :destroy, inverse_of: :project
    has_many :project_custom_fields, through: :project_custom_field_project_mappings, class_name: 'ProjectCustomField'

    before_save :build_missing_project_custom_field_project_mappings
    after_create :disable_custom_fields_with_empty_values

    def build_missing_project_custom_field_project_mappings
      # activate custom fields for this project (via mapping table) if values have been provided for custom_fields but no mapping exists
      # current shortcommings:
      # - boolean custom fields are always activated as a nil value is never provided (always true/false)
      custom_field_ids = project.custom_values.reject { |cv| cv.value.blank? }.pluck(:custom_field_id).uniq
      activated_custom_field_ids = project_custom_field_project_mappings.pluck(:custom_field_id).uniq

      mappings = (custom_field_ids - activated_custom_field_ids)
        .map { |pcf_id| { project_id: id, custom_field_id: pcf_id } }

      project_custom_field_project_mappings.build(mappings)
    end

    def disable_custom_fields_with_empty_values
      # run only on initial creation! (otherwise we would deactivate custom fields with empty values on every update!)
      #
      # ideally, `build_missing_project_custom_field_project_mappings` would not activate custom fields with empty values
      # but:
      # this hook is required as acts_as_customizable build custom values with their default value even if a blank value was provided in the project creation form
      # `build_missing_project_custom_field_project_mappings` will then activate the custom field although the user explicitly provided a blank value
      # in order to not patch `acts_as_customizable` further, we simply identify these custom values and deactivate the custom field
      custom_field_ids = project.custom_values.select { |cv| cv.value.blank? && !cv.required? }.pluck(:custom_field_id)

      project_custom_field_project_mappings.where(custom_field_id: custom_field_ids).destroy_all
    end

    def active_custom_field_ids_of_project
      # show all project custom fields in the project creation form
      # later on, only those with values will be activated via before_save hook `build_missing_project_custom_field_project_mappings`
      # a persisted project will then only show the activated custom fields
      # this approach also supports project duplication based on project templates
      if new_record?
        ProjectCustomField.pluck(:id)
      else
        project_custom_field_project_mappings.pluck(:custom_field_id)
      end
    end

    def available_custom_fields
      # overrides acts_as_customizable
      # in contrast to acts_as_customizable, custom_fields are enabled per project
      # thus we need to check the project_custom_field_project_mappings
      ProjectCustomField
        .includes(:project_custom_field_section)
        .where(id: active_custom_field_ids_of_project)
    end

    def available_project_custom_fields_grouped_by_section
      sorted_available_custom_fields
        .group_by(&:custom_field_section_id)
    end

    def available_custom_fields_by_section(section)
      available_custom_fields
        .where(custom_field_section_id: section.id)
    end

    def sorted_available_custom_fields
      available_custom_fields
        .sort_by { |pcf| [pcf.project_custom_field_section.position, pcf.position_in_custom_field_section] }
    end

    def sorted_available_custom_fields_by_section(section)
      available_custom_fields_by_section(section)
        .sort_by(&:position_in_custom_field_section)
    end

    def custom_field_section_ids
      # we need to check if a project custom field belongs to a specific section when validating
      # we need a mapping of custom_field_id => custom_field_section_id as we don't want to
      # change the code of acts_as_customizable for `custom_field_values` which does not include the custom_field_section_id
      # preloading a hash avoids n+1 queries while validating
      CustomField
        .where(id: custom_field_values.pluck(:custom_field_id))
        .pluck(:id, :custom_field_section_id)
        .to_h
    end

    def validate_custom_values
      # overrides acts_as_customizable
      # validate custom values only of a specified section
      # instead of validating ALL custom values like done in acts_as_customizable
      set_default_values! if new_record?

      custom_field_values
        .select { |custom_value| of_specified_custom_field_section?(custom_value) }
        .reject(&:marked_for_destruction?)
        .select(&:invalid?)
        .each { |custom_value| add_custom_value_errors! custom_value }
    end

    def of_specified_custom_field_section?(custom_value)
      if limit_custom_fields_validation_to_section_id.present?
        custom_field_section_ids[custom_value.custom_field_id] == limit_custom_fields_validation_to_section_id
      else
        true # validate all custom values if no specific section was specified
      end
    end
  end
end

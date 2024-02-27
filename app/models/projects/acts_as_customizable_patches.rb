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

  attr_accessor :_limit_custom_fields_validation_to_section_id, :_query_available_custom_fields_on_global_level

  # attr_accessor :_limit_custom_fields_validation_to_field_id
  # not needed for now, but might be relevant if we want to have edit dialogs just for one custom field

  included do
    has_many :project_custom_field_project_mappings, class_name: 'ProjectCustomFieldProjectMapping', foreign_key: :project_id,
                                                     dependent: :destroy, inverse_of: :project
    has_many :project_custom_fields, through: :project_custom_field_project_mappings, class_name: 'ProjectCustomField'

    before_save :build_missing_project_custom_field_project_mappings
    after_save :reset_section_scoped_validation, :reset_query_available_custom_fields_on_global_level

    # we need to reset the query_available_custom_fields_on_global_level already after validation
    # as the update service just calls .valid? and returns if invalid
    # after_save is not touched in this case which causes the flag to stay active
    after_validation :reset_query_available_custom_fields_on_global_level

    before_update :query_available_custom_fields_on_global_level

    before_create :reject_section_scoped_validation_for_creation
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

    def reset_section_scoped_validation
      # reset the section scope after saving
      # in order not to silently carry this setting in this instance
      self._limit_custom_fields_validation_to_section_id = nil
    end

    def query_available_custom_fields_on_global_level
      # query the available custom fields on a global level when updating custom field values
      # in order to support implicit activation of custom fields when values are provided during an update
      self._query_available_custom_fields_on_global_level = true
    end

    def reset_query_available_custom_fields_on_global_level
      # reset the query_available_custom_fields_on_global_level after saving
      # in order not to silently carry this setting in this instance
      self._query_available_custom_fields_on_global_level = nil
    end

    def reject_section_scoped_validation_for_creation
      if _limit_custom_fields_validation_to_section_id.present?
        raise ArgumentError,
              'Section scoped validation is not supported for project creation, only for project updates'
      end
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
          .concat(ProjectCustomField.required.pluck(:id))
          .uniq
        # if for whatever reason a required custom field is not activated for this instance,
        # we need to make sure it's treated as activated especially in context of the validation
      end
    end

    def available_custom_fields
      # overrides acts_as_customizable
      # in contrast to acts_as_customizable, custom_fields are enabled per project
      # thus we need to check the project_custom_field_project_mappings
      custom_fields = ProjectCustomField
        .includes(:project_custom_field_section)

      # available_custom_fields is called from within the acts_as_customizable module
      # we don't want to adjust these calls, but need a way to query the available custom fields on a global level in some cases
      # thus we pass in this parameter as an instance flag implicitly here,
      # which is not nice but helps us to touch acts_as_customizable as little as possible
      unless _query_available_custom_fields_on_global_level
        custom_fields = custom_fields.where(id: active_custom_field_ids_of_project)
      end

      custom_fields
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
      if _limit_custom_fields_validation_to_section_id.present?
        custom_field_section_ids[custom_value.custom_field_id] == _limit_custom_fields_validation_to_section_id
      else
        true # validate all custom values if no specific section was specified
      end
    end

    def custom_field_values=(values)
      # overrides acts_as_customizable
      # we need to query the available custom fields on a global level when updating custom field values
      # in order to support implicit activation of custom fields when values are provided during an update
      self._query_available_custom_fields_on_global_level = true # set to false in after_save hook
      set_custom_field_values_method_from_acts_as_customizable_module(values)
    end

    # we cannot call super as the code in acts_as_customizable is shipped in a module
    # thus copy and pasted the code from acts_as_customizable here
    def set_custom_field_values_method_from_acts_as_customizable_module(values)
      return unless values.is_a?(Hash) && values.any?

      values.with_indifferent_access.each do |custom_field_id, val|
        existing_cv_by_value = custom_values_for_custom_field(id: custom_field_id)
                                 .group_by(&:value)
                                 .transform_values(&:first)
        new_values = Array(val).map { |v| v.respond_to?(:id) ? v.id.to_s : v.to_s }

        if existing_cv_by_value.any?
          assign_new_values custom_field_id, existing_cv_by_value, new_values
          delete_obsolete_custom_values existing_cv_by_value, new_values
          handle_minimum_custom_value custom_field_id, existing_cv_by_value, new_values
        end
      end
    end
  end
end

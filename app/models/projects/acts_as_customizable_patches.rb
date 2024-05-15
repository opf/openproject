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
    has_many :project_custom_field_project_mappings, class_name: "ProjectCustomFieldProjectMapping", foreign_key: :project_id,
                                                     dependent: :destroy, inverse_of: :project
    has_many :project_custom_fields, through: :project_custom_field_project_mappings, class_name: "ProjectCustomField"

    # we need to reset the query_available_custom_fields_on_global_level already after validation
    # as the update service just calls .valid? and returns if invalid
    # after_save is not touched in this case which causes the flag to stay active
    after_validation :set_query_available_custom_fields_to_project_level

    before_update :set_query_available_custom_fields_to_global_level

    before_create :reject_section_scoped_validation_for_creation
    before_create :build_missing_project_custom_field_project_mappings

    after_save :reset_section_scoped_validation, :set_query_available_custom_fields_to_project_level
    after_save :disable_custom_fields_with_empty_values, if: :previously_new_record?

    def build_missing_project_custom_field_project_mappings
      # activate custom fields for this project (via mapping table) if values have been provided for custom_fields but no mapping exists
      custom_field_ids = project.custom_values
        .select { |cv| cv.value.present? }
        .pluck(:custom_field_id).uniq
      activated_custom_field_ids = project_custom_field_project_mappings.pluck(:custom_field_id).uniq

      mappings = (custom_field_ids - activated_custom_field_ids).uniq
        .map { |pcf_id| { project_id: id, custom_field_id: pcf_id } }

      project_custom_field_project_mappings.build(mappings)
    end

    def reset_section_scoped_validation
      # reset the section scope after saving
      # in order not to silently carry this setting in this instance
      self._limit_custom_fields_validation_to_section_id = nil
    end

    def set_query_available_custom_fields_to_global_level
      # query the available custom fields on a global level when updating custom field values
      # in order to support implicit activation of custom fields when values are provided during an update
      self._query_available_custom_fields_on_global_level = true
    end

    def set_query_available_custom_fields_to_project_level
      # reset the query_available_custom_fields_on_global_level after saving
      # in order not to silently carry this setting in this instance
      self._query_available_custom_fields_on_global_level = nil
    end

    def reject_section_scoped_validation_for_creation
      if _limit_custom_fields_validation_to_section_id.present?
        raise ArgumentError,
              "Section scoped validation is not supported for project creation, only for project updates"
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

      # This callback should be an after_save callback, because the custom_values association has autosave
      # and it has after_create callbacks in the model (CustomValue#activate_custom_field_in_customized_project).
      # The after_create callback in the children objects are ran after the after_create callbacks on the parent.
      # In order to make sure we execute this callback after the children's callbacks, the after_save hook must be used.
      custom_field_ids = project.custom_values.select { |cv| cv.value.blank? && !cv.required? }.pluck(:custom_field_id)

      project_custom_field_project_mappings
        .where(custom_field_id: custom_field_ids)
        .or(project_custom_field_project_mappings
          .where.not(custom_field_id: available_custom_fields.select(:id)))
        .destroy_all
    end

    def with_all_available_custom_fields
      # query the available custom fields on a global level when updating custom field values
      # in order to support implicit activation of custom fields when values are provided during an update
      self._query_available_custom_fields_on_global_level = true
      result = yield
      self._query_available_custom_fields_on_global_level = nil

      result
    end

    def available_custom_fields
      # TODO: Add caching here.
      # overrides acts_as_customizable
      # in contrast to acts_as_customizable, custom_fields are enabled per project
      # thus we need to check the project_custom_field_project_mappings
      custom_fields = ProjectCustomField
        .includes(:project_custom_field_section)
        .order("custom_field_sections.position", :position_in_custom_field_section)

      # Do not hide the invisble fields when accessing via the _query_available_custom_fields_on_global_level
      # flag. Due to the internal working of the acts_as_customizable plugin, when a project admin updates
      # the custom fields, it will clear out all the hidden fields that are not visible for them.
      # This happens because the `#ensure_custom_values_complete` will gather all the `custom_field_values`
      # and assigns them to the custom_fields association. If the `custom_field_values` do not contain the
      # hidden fields, they will be cleared from the association. The `custom_field_values` will contain the
      # hidden fields, only if they are returned from this method. Hence we should not hide them,
      # when accessed with the _query_available_custom_fields_on_global_level flag on.
      unless _query_available_custom_fields_on_global_level
        custom_fields = custom_fields.visible
      end

      # available_custom_fields is called from within the acts_as_customizable module
      # we don't want to adjust these calls, but need a way to query the available custom fields on a global level in some cases
      # thus we pass in this parameter as an instance flag implicitly here,
      # which is not nice but helps us to touch acts_as_customizable as little as possible
      #
      # additionally we provide the `global` parameter to allow querying the available custom fields on a global level
      # when we have explicit control over the call of `available_custom_fields`
      unless new_record? || _query_available_custom_fields_on_global_level
        custom_fields = custom_fields
          .where(id: project_custom_field_project_mappings.select(:custom_field_id))
          .or(ProjectCustomField.required)
      end

      custom_fields
    end

    def all_available_custom_fields
      with_all_available_custom_fields { available_custom_fields }
    end

    def custom_fields_to_validate
      custom_fields = available_custom_fields
      # Limit the set of available custom fields when the validation is limited to a section
      if _limit_custom_fields_validation_to_section_id
        custom_fields =
          custom_fields.where(custom_field_section_id: _limit_custom_fields_validation_to_section_id)
      end
      custom_fields
    end

    # we need to query the available custom fields on a global level when updating custom field values
    # in order to support implicit activation of custom fields when values are provided during an update
    def custom_field_values=(values)
      with_all_available_custom_fields { super }
    end

    # We need to query the available custom fields on a global level when
    # trying to set a custom field which is not enabled via the API e.g. custom_field_123="foo"
    # This implies implicit activation of the disabled custom fields via the API. As a side effect,
    # we will have empty CustomValue objects created for each custom field, regardless of its
    # enabled/disabled state in the project.
    def for_custom_field_accessor(method_symbol)
      with_all_available_custom_fields { super }
    end
  end
end

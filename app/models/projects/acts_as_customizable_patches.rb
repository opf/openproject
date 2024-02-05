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

  attr_accessor :touched_custom_field_section_id

  included do
    def active_custom_field_ids_of_project
      @active_custom_field_ids_of_project ||= ProjectCustomFieldProjectMapping
        .where(project_id: project.id)
        .pluck(:custom_field_id)
    end

    def available_custom_fields
      # overrides acts_as_customizable
      # in contrast to acts_as_customizable, custom_fields are enabled per project
      # thus we need to check the project_custom_field_project_mappings
      @available_custom_fields ||= ProjectCustomField
        .includes(:project_custom_field_section)
        .where(id: active_custom_field_ids_of_project)
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
      # validate custom values only of the touched section
      # instead of validating ALL custom values like done in acts_as_customizable
      set_default_values! if new_record?

      custom_field_values
        .select { |custom_value| of_touched_custom_field_section?(custom_value) }
        .reject(&:marked_for_destruction?)
        .select(&:invalid?)
        .each { |custom_value| add_custom_value_errors! custom_value }
    end

    def of_touched_custom_field_section?(custom_value)
      if touched_custom_field_section_id.present?
        custom_field_section_ids[custom_value.custom_field_id] == touched_custom_field_section_id
      else
        true # validate all custom values if no specific section was marked as touched via `update_custom_field_values_of_section`
      end
    end
  end
end

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

module Projects::CustomFields
  extend ActiveSupport::Concern

  attr_accessor :_limit_custom_fields_validation_to_section_id

  included do
    has_many :project_custom_field_project_mappings, class_name: "ProjectCustomFieldProjectMapping",
                                                     foreign_key: :project_id, dependent: :destroy,
                                                     inverse_of: :project
    has_many :project_custom_fields, through: :project_custom_field_project_mappings,
                                     class_name: "ProjectCustomField"

    def available_custom_fields
      return all_visible_custom_fields if new_record?

      all_visible_custom_fields.where(id: project_custom_field_project_mappings.select(:custom_field_id))
    end

    # Note:
    #
    # The UI allows the enabled attributes only via the project_custom_field_project_mappings.
    # The API still provides the old behaviour where all the custom fields are available regardless
    # of the enabled mapping. Once the api behaviour is aligned to the UI behaviour, this method
    # can be removed in favour of the available_custom_fields.
    # As a future improvement a flag `via_api=true` can be set on the project when the
    # modification happens via the api, then set the available_custom_fields accordingly. This allows
    # the extension to be completely removed from the acts_as_customizable plugin.
    def all_available_custom_fields
      @all_available_custom_fields ||= ProjectCustomField
        .includes(:project_custom_field_section)
        .order("custom_field_sections.position", :position_in_custom_field_section)
    end

    def all_visible_custom_fields
      all_available_custom_fields.visible(project: self)
    end

    def custom_field_values_to_validate
      # Limit the set of available custom fields when the validation is limited to a section
      if _limit_custom_fields_validation_to_section_id
        custom_field_values.select do |cfv|
          cfv.custom_field.custom_field_section_id == _limit_custom_fields_validation_to_section_id
        end
      else
        custom_field_values
      end
    end
  end
end

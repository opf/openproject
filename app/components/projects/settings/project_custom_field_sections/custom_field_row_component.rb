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

module Projects
  module Settings
    module ProjectCustomFieldSections
      class CustomFieldRowComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(project:, project_custom_field:)
          super

          @project = project
          @project_custom_field = project_custom_field
          @project_custom_field_project_mappings = project.project_custom_field_project_mappings
        end

        private

        def wrapper_uniq_by
          @project_custom_field.id
        end

        def active_in_project?
          @project_custom_field_project_mappings.any? do |mapping|
            mapping.custom_field_id == @project_custom_field.id
          end
        end

        def toggle_path
          toggle_project_settings_project_custom_fields_path(
            project_custom_field_project_mapping: {
              project_id: @project.id,
              custom_field_id: @project_custom_field.id
            }
          )
        end

        def toggle_checked?
          active_in_project? || toggle_force_checked?
        end

        def toggle_force_checked?
          @project_custom_field.is_for_all? ||
            configured_as_creation_wizard_assignee?
        end

        def toggle_enabled? = !toggle_disabled?

        def toggle_disabled? = toggle_force_checked?

        def toggle_data_attributes
          {
            "turbo-method": :put,
            "turbo-stream": true,
            test_selector: "toggle-project-custom-field-mapping-#{@project_custom_field.id}"
          }.tap do |data|
            if toggle_disabled?
              # Add hover card that explains why this toggle switch is disabled
              data[:hover_card_trigger_target] = "trigger"
              data[:hover_card_popover_template_id] = unique_hovercard_id
            end
          end
        end

        def configured_as_creation_wizard_assignee?
          @project.project_creation_wizard_enabled? &&
            @project.project_creation_wizard_assignee_custom_field_id == @project_custom_field.id
        end

        def unique_hovercard_id
          "project-custom-field-#{@project_custom_field.id}-disabled-reason"
        end
      end
    end
  end
end

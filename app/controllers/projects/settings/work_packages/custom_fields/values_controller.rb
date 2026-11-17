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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  module Settings
    module WorkPackages
      module CustomFields
        class ValuesController < ::Projects::SettingsController
          include ::CustomFields::ProjectSpecificValueActions

          menu_item :settings_work_packages

          before_action :require_custom_field_in_project
          before_action :require_project_value_management

          private

          def custom_field
            @custom_field ||= WorkPackageCustomField.find(params.expect(:custom_field_id))
          end

          def configured_project = @project

          def require_custom_field_in_project
            render_404 unless Project.where(id: @project.id).with_available_custom_fields([custom_field.id]).exists?
          end

          def require_project_value_management
            return if custom_field.project_level_value_management? || custom_field.allow_additional_project_values?

            render_404
          end

          def values_path
            project_settings_work_packages_custom_field_values_path(configured_project, custom_field)
          end

          def new_value_path(parent_id: nil)
            new_project_settings_work_packages_custom_field_value_path(configured_project, custom_field, parent_id:)
          end

          def value_path(value_id)
            project_settings_work_packages_custom_field_value_path(configured_project, custom_field, value_id)
          end

          def edit_value_path(value_id)
            edit_project_settings_work_packages_custom_field_value_path(configured_project, custom_field, value_id)
          end

          def toggle_value_path(value_id)
            toggle_project_settings_work_packages_custom_field_value_path(configured_project, custom_field, value_id)
          end

          def make_global_value_path(value_id)
            make_global_project_settings_work_packages_custom_field_value_path(configured_project, custom_field, value_id)
          end

          def value_deletion_dialog_path(value_id)
            deletion_dialog_project_settings_work_packages_custom_field_value_path(configured_project, custom_field, value_id)
          end

          def enable_all_values_path
            enable_all_project_settings_work_packages_custom_field_values_path(configured_project, custom_field)
          end

          def disable_all_values_path
            disable_all_project_settings_work_packages_custom_field_values_path(configured_project, custom_field)
          end
        end
      end
    end
  end
end

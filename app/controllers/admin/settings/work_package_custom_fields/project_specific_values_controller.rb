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

module Admin
  module Settings
    module WorkPackageCustomFields
      class ProjectSpecificValuesController < ::Admin::SettingsController
        include ::CustomFields::ProjectSpecificValueActions

        menu_item :work_package_custom_fields

        before_action :configured_project

        helper_method :custom_field_page_title, :section_label

        private

        def find_custom_field
          @custom_field = WorkPackageCustomField.find(params.expect(:work_package_custom_field_id))
        end

        # Not @project, as the layout would then announce the project as the current one.
        def configured_project
          @configured_project ||= Project.active
                                         .with_available_custom_fields([@custom_field.id])
                                         .find(params.expect(:project_id))
        end

        def values_path
          admin_settings_work_package_custom_field_project_specific_values_path(@custom_field, configured_project)
        end

        def custom_field_page_title
          t(:label_custom_field_plural)
        end

        def section_label
          t(:label_work_package_plural)
        end
      end
    end
  end
end

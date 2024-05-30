#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Settings
  module ProjectCustomFields
    module ProjectCustomFieldMapping
      class NewProjectMappingComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
        options dialog_id: "settings--new-project-custom-field-mapping-component",
                dialog_body_id: "settings--new-project-custom-field-mapping-body-component"

        def initialize(project_mapping:, project_custom_field:, **)
          @project_mapping = project_mapping
          @project_custom_field = project_custom_field
          super(@project_mapping, **)
        end

        private

        def title
          I18n.t("projects.settings.project_custom_fields.new_project_mapping_form.add_projects")
        end

        def show_button_text
          I18n.t("projects.settings.project_custom_fields.new_project_mapping_form.add_projects")
        end

        def cancel_button_text
          I18n.t("button_cancel")
        end

        def submit_button_text
          I18n.t("button_add")
        end
      end
    end
  end
end

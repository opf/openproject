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

module Projects::CustomFields
  class CustomFieldMappingForm < ApplicationForm
    form do |f|
      f.group(layout: :horizontal) do |f_group|
        f_group.project_autocompleter(
          name: :id,
          label: Project.model_name.human,
          visually_hide_label: true,
          autocomplete_options: {
            openDirectly: false,
            focusDirectly: false,
            dropdownPosition: "bottom",
            disabledProjects: projects_with_custom_field_mapping,
            inputName: "project_custom_field_project_mapping[project_id]"
          }
        )

        f_group.check_box(
          name: :include_sub_projects,
          label: I18n.t("projects.settings.project_custom_fields.new_project_mapping_form.include_sub_projects"),
          checked: false,
          label_arguments: { class: "no-wrap" }
        )
      end
    end

    def initialize(project_custom_field:)
      super()
      @project_custom_field = project_custom_field
    end

    private

    def projects_with_custom_field_mapping
      ProjectCustomFieldProjectMapping
        .where(project_custom_field: @project_custom_field)
        .pluck(:project_id)
        .to_h { |id| [id, id] }
    end
  end
end

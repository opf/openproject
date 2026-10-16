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
    class ProjectSettingsForm < ApplicationForm
      settings_form do |sf|
        sf.html_content do
          render(
            Admin::Settings::ColumnSelectionComponent.new(
              name: :enabled_projects_columns,
              columns: helpers.projects_columns_options,
              selected: helpers.selected_projects_columns_options,
              protected: helpers.protected_projects_columns_options
            )
          )
        end
        sf.fieldset_group(title: I18n.t(:setting_project_gantt_query),
                          description: I18n.t(:setting_project_gantt_query_text),
                          data: { setting_name: "project_gantt_query" }) do |fg|
          fg.html_content do
            helpers.angular_component_tag(
              "opce-editable-query-props",
              data: {
                name: "settings[project_gantt_query]",
                id: "settings_project_gantt_query",
                query: ::Projects::GanttQueryGeneratorService.current_query,
                "url-params": "true"
              }
            )
          end
        end
      end
    end
  end
end

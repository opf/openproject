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

module Storages
  module Admin
    module Storages
      class AddProjectsAutocompleterForm < ApplicationForm
        form do |form|
          form.group(layout: :vertical) do |group|
            group.project_autocompleter(
              name: :id,
              label: Project.model_name.human,
              visually_hide_label: true,
              validation_message: project_ids_error_message,
              autocomplete_options: {
                with_search_icon: true,
                openDirectly: false,
                focusDirectly: false,
                multiple: true,
                dropdownPosition: "bottom",
                disabledProjects: projects_with_storage_mapping,
                inputName: "storages_project_storage[project_ids]"
              }
            )

            group.check_box(
              name: :include_sub_projects,
              label: I18n.t(:label_include_sub_projects),
              checked: false,
              label_arguments: { class: "no-wrap" }
            )
          end
        end

        def initialize(project_storage:)
          super()
          @project_storage = project_storage
        end

        private

        def project_ids_error_message
          @project_storage
            .errors
            .messages_for(:project_ids)
            .to_sentence
            .presence
        end

        def projects_with_storage_mapping
          ::Storages::ProjectStorage
            .where(storage_id: @project_storage.storage.id)
            .pluck(:project_id)
            .to_h { |id| [id, id] }
        end
      end
    end
  end
end

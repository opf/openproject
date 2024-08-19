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
    module ProjectStorages
      class ProjectFolderModeForm < ApplicationForm
        include StorageLoginHelper
        include APIV3Helper

        form do |radio_form|
          radio_form.radio_button_group(name: :project_folder_mode, validation_message:) do |radio_group|
            if @project_storage.project_folder_mode_possible?("inactive")
              radio_group.radio_button(value: "inactive", label: I18n.t(:"storages.label_no_specific_folder"),
                                       caption: I18n.t(:"storages.instructions.no_specific_folder"),
                                       data: { action: "storages--project-folder-mode-form#updateForm" })
            end

            if @project_storage.project_folder_mode_possible?("automatic")
              radio_group.radio_button(value: "automatic", label: I18n.t(:"storages.label_automatic_folder"),
                                       caption: I18n.t(:"storages.instructions.automatic_folder"),
                                       data: { action: "storages--project-folder-mode-form#updateForm" })
            end

            if @project_storage.project_folder_mode_possible?("manual")
              radio_group.radio_button(value: "manual", label: I18n.t(:"storages.label_existing_manual_folder"),
                                       caption: I18n.t(:"storages.instructions.existing_manual_folder"),
                                       data: { action: "storages--project-folder-mode-form#updateForm" })
            end
          end

          radio_form.hidden(
            name: :storage,
            value: @project_storage.storage_id,
            data: {
              "storages--project-folder-mode-form-target": "storage",
              storage: {
                name: @project_storage.storage.name,
                id: @project_storage.storage.id,
                _links: {
                  self: { href: api_v3_paths.storage(@project_storage.storage.id) },
                  type: { href: API::V3::Storages::URN_STORAGE_TYPE_NEXTCLOUD }
                }
              }
            }
          )

          radio_form.hidden(
            name: :project_folder_id,
            data: {
              "storages--project-folder-mode-form-target": "projectFolderIdInput"
            }
          )

          if @project_storage.project_folder_mode_possible?("manual")
            radio_form.storage_manual_project_folder_selection(
              name: :project_folder,
              label: nil,
              project_storage: @project_storage,
              last_project_folders: @last_project_folders,
              storage_login_button_options: {
                data: {
                  "storages--project-folder-mode-form-target": "loginButton"
                },
                inputs: {
                  input: storage_login_input(@project_storage.storage)
                }
              },
              select_folder_button_options: {
                data: {
                  "storages--project-folder-mode-form-target": "selectProjectFolderButton",
                  action: "storages--project-folder-mode-form#selectProjectFolder"
                },
                selected_folder_label_options: {
                  data: {
                    "storages--project-folder-mode-form-target": "selectedFolderText"
                  }
                }
              },
              wrapper_arguments: {
                data: {
                  "storages--project-folder-mode-form-target": "projectFolderSection"
                },
                classes: project_folder_selection_classes
              }
            )
          end
        end

        def initialize(project_storage:, last_project_folders: {})
          super()
          @project_storage = project_storage
          @last_project_folders = last_project_folders
        end

        private

        def validation_message
          @project_storage
            .errors
            .messages_for(:project_folder_id)
            .to_sentence
            .presence
        end

        def project_folder_selection_classes
          [].tap do |classes|
            classes << "d-none" unless show_project_folder_selection?
          end
        end

        def show_project_folder_selection?
          @project_storage.project_folder_manual? || @project_storage.errors.include?(:project_folder_id)
        end
      end
    end
  end
end

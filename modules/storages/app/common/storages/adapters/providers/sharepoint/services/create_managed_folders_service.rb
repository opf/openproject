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

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Services
          class CreateManagedFoldersService < BaseService
            using Peripherals::ServiceResultRefinements

            def self.i18n_key = "sharepoint_sync_service"

            class << self
              def call(storage:, project_storages_scope: nil)
                new(storage:, project_storages_scope:).call
              end
            end

            def initialize(storage:, project_storages_scope:, hide_missing_folders: project_storages_scope.nil?)
              super()
              @storage = storage
              @hide_missing_folders = hide_missing_folders
              @project_storages = (project_storages_scope || @storage.project_storages).active.automatic
            end

            def call
              with_tagged_logger([self.class.name, "storage-#{@storage.id}"]) do
                remote_folders_map.bind do |existing_remote_folders|
                  ensure_folders_exist(existing_remote_folders).bind do
                    hide_inactive_folders(existing_remote_folders) if @hide_missing_folders
                  end
                end

                @result
              end
            end

            private

            def ensure_folders_exist(folder_map)
              info "Ensuring that automatically managed project folders exist and are correctly named."
              @project_storages.includes(:project).find_each do |project_storage|
                unless folder_map.key?(project_storage.project_folder_id)
                  info "#{project_storage.managed_project_folder_path} does not exist. Creating..."
                  next create_remote_folder(project_storage.managed_project_folder_name, project_storage)
                end

                rename_project_folder(folder_map[project_storage.project_folder_id], project_storage)
              end

              Success(:folder_maintenance_done)
            end

            def hide_inactive_folders(folder_map)
              info "Hiding folders related to inactive projects"

              inactive_folder_ids(folder_map).each { |item_id| hide_folder(item_id, folder_map) }
            end

            def hide_folder(file_id, folder_map)
              info "Hiding folder with ID #{file_id} as it does not belong to any active project"

              input_data = Adapters::Input::SetPermissions.build(file_id:, user_permissions: []).value_or do |failure|
                log_validation_error(failure, file_id:, context: "hide_folder")
                return Failure(:hide_inactive_folders)
              end

              set_permissions.call(auth_strategy:, input_data:).or do |error|
                add_error(:hide_inactive_folders, error, options: { context: "hide folders", path: folder_map[item_id] })
              end
            end

            def inactive_folder_ids(folder_map)
              folder_map.keys - @project_storages.pluck(:project_folder_id).compact
            end

            def rename_project_folder(current_folder_name, project_storage)
              actual_name = project_storage.managed_project_folder_name
              return if current_folder_name == actual_name

              info "#{current_folder_name} is misnamed. Renaming to #{actual_name}"
              folder_id = project_storage.project_folder_id

              Adapters::Input::RenameFile.build(location: folder_id, new_name: actual_name).bind do |input_data|
                rename_file.call(auth_strategy:, input_data:).or do |error|
                  add_error(
                    :rename_project_folder, error,
                    options: { current_path: current_folder_name, project_folder_name: actual_name, project_folder_id: folder_id }
                  )
                end
              end
            end

            def create_remote_folder(folder_name, project_storage)
              input_data = Adapters::Input::CreateFolder
                .build(folder_name:, parent_location: drive_id)
                .value_or { return Failure(log_validation_error(it, folder_name: folder_name, parent_location: drive_id)) }

              folder_info = create_folder.call(auth_strategy:, input_data:).value_or do |error|
                add_error(:create_folder, error, options: { folder_name:, parent_location: drive_name })
                return Failure()
              end

              project_storage.update(project_folder_id: folder_info.id)
            end

            def remote_folders_map
              info "Retrieving already existing folders under #{drive_id}"

              input_data = Adapters::Input::Files.build(folder: "/#{drive_name}").value_or do |error|
                log_validation_error(error, context: "remote_folders")
                return Failure()
              end

              file_list = files.call(auth_strategy:, input_data:).value_or do |error|
                add_error(:remote_folders, error, options: { drive_name: })
                return Failure()
              end

              filter_folders_from(file_list)
            end

            def filter_folders_from(files)
              folder_map = files.all_folders.to_h { [it.id, it.name] }
              info "Found #{folder_map.size} folders. Map: #{folder_map}"
              Success(folder_map)
            end

            def drive_id = @storage.managed_drive_id
            def drive_name = @storage.managed_drive_name

            def create_folder = Adapters::Registry.resolve("sharepoint.commands.create_folder").new(@storage)

            def rename_file = Adapters::Registry.resolve("sharepoint.commands.rename_file").new(@storage)

            def set_permissions = Adapters::Registry.resolve("sharepoint.commands.set_permissions").new(@storage)

            def files = Adapters::Registry.resolve("sharepoint.queries.files").new(@storage)

            def auth_strategy
              @auth_strategy ||= Adapters::Registry["onedrive.authentication.userless"].call
            end
          end
        end
      end
    end
  end
end

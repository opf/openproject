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
  class OneDriveManagedFolderCreateService < BaseService
    using Peripherals::ServiceResultRefinements

    def self.i18n_key = "one_drive_sync_service"

    class << self
      def call(storage:, project_storages_scope: nil)
        new(storage:, project_storages_scope:).call
      end
    end

    def initialize(storage:, project_storages_scope: nil)
      super()
      @storage = storage
      @hide_missing_folders = project_storages_scope.nil?
      @project_storages = (project_storages_scope || @storage.project_storages).active.automatic
    end

    def call
      with_tagged_logger([self.class.name, "storage-#{@storage.id}"]) do
        remote_folders_map(@storage.drive_id).bind do |existing_remote_folders|
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
          next create_remote_folder(project_storage.managed_project_folder_path, project_storage.id)
        end

        rename_project_folder(folder_map[project_storage.project_folder_id], project_storage)
      end

      Success(:folder_maintenance_done)
    end

    def hide_inactive_folders(folder_map)
      info "Hiding folders related to inactive projects"

      inactive_folder_ids(folder_map).each { |item_id| hide_folder(item_id, folder_map) }
    end

    def hide_folder(item_id, folder_map)
      info "Hiding folder with ID #{item_id} as it does not belong to any active project"

      build_permissions_input_data(item_id, [])
        .either(
          ->(input_data) do
            set_permissions.call(auth_strategy:, input_data:).or do |error|
              add_error(:hide_inactive_folders, error, options: { context: "hide folders", path: folder_map[item_id] })
            end
          end,
          ->(failure) { log_validation_error(failure, item_id:, context: "hide_folder") }
        )
    end

    def inactive_folder_ids(folder_map)
      folder_map.keys - @project_storages.pluck(:project_folder_id).compact
    end

    def rename_project_folder(current_folder_name, project_storage)
      actual_path = project_storage.managed_project_folder_path
      return if current_folder_name == actual_path

      info "#{current_folder_name} is misnamed. Renaming to #{actual_path}"
      folder_id = project_storage.project_folder_id

      Adapters::Input::RenameFile.build(location: folder_id, new_name: actual_path).bind do |input_data|
        rename_file.call(auth_strategy:, input_data:).or do |error|
          add_error(
            :rename_project_folder, error,
            options: { current_path: current_folder_name, project_folder_name: actual_path, project_folder_id: folder_id }
          )
        end
      end
    end

    def create_remote_folder(folder_name, project_storage_id)
      input_data = Adapters::Input::CreateFolder
                     .build(folder_name:, parent_location: "/")
                     .value_or { return Failure(log_validation_error(it, folder_name: folder_name, parent_location: "/")) }

      folder_info = create_folder.call(auth_strategy:, input_data:).value_or do |error|
        add_error(:create_folder, error, options: { folder_name:, parent_location: "/" })
        return Failure()
      end

      last_project_folder = LastProjectFolder.find_by(project_storage_id:, mode: :automatic)

      audit_last_project_folder(last_project_folder, folder_info.id)
    end

    def audit_last_project_folder(last_project_folder, project_folder_id)
      ApplicationRecord.transaction do
        success =
          last_project_folder.update(origin_folder_id: project_folder_id) &&
            last_project_folder.project_storage.update(project_folder_id:)

        raise ActiveRecord::Rollback unless success
      end
    end

    def remote_folders_map(drive_id)
      info "Retrieving already existing folders under #{drive_id}"

      input_data = Adapters::Input::Files.build(folder: "/").value_or do |it|
        log_validation_error(it, context: "remote_folders")
        return Failure()
      end

      file_list = files.call(auth_strategy:, input_data:).value_or do |error|
        add_error(:remote_folders, error, options: { drive_id: })
        return Failure()
      end

      filter_folders_from(file_list)
    end

    def filter_folders_from(files)
      folder_map = files.all_folders.to_h { [it.id, it.name] }
      info "Found #{folder_map.size} folders. Map: #{folder_map}"
      Success(folder_map)
    end

    def root_folder = "/"

    def create_folder = Adapters::Registry.resolve("onedrive.commands.create_folder").new(@storage)

    def rename_file = Adapters::Registry.resolve("onedrive.commands.rename_file").new(@storage)

    def set_permissions = Adapters::Registry.resolve("onedrive.commands.set_permissions").new(@storage)

    def files = Adapters::Registry.resolve("onedrive.queries.files").new(@storage)

    def build_permissions_input_data(file_id, user_permissions)
      Adapters::Input::SetPermissions.build(file_id:, user_permissions:)
    end

    def auth_strategy
      @auth_strategy ||= Adapters::Registry["onedrive.authentication.userless"].call
    end
  end
end

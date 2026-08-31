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
  class NextcloudManagedFolderCreateService < BaseService
    using Peripherals::ServiceResultRefinements

    FILE_PERMISSIONS = OpenProject::Storages::Engine.external_file_permissions

    delegate :group, :group_folder, :username, to: :@storage, private: true

    class << self
      def i18n_key = "nextcloud_sync_service"

      def call(storage:, project_storages_scope: nil)
        new(storage:, project_storages_scope:).call
      end
    end

    def initialize(storage:, project_storages_scope: nil)
      super()
      @storage = storage

      @hide_missing_folders = project_storages_scope.nil?
      @project_storages = (project_storages_scope || storage.project_storages).active.automatic
      setup_commands
    end

    def call
      with_tagged_logger([self.class.name, "storage-#{@storage.id}"]) do
        prepare_remote_folders
        @result
      end
    end

    private

    # rubocop:disable Metrics/AbcSize
    def prepare_remote_folders
      info "Preparing the remote team folder #{group_folder}"

      remote_root_folder_map.bind do |remote_folders|
        info "Found #{remote_folders.count} remote folders"

        root_folder = remote_folders.delete("/#{group_folder}")
        ensure_root_folder_permissions(root_folder.id).bind do
          ensure_folders_exist(remote_folders.invert).bind do
            hide_inactive_folders(remote_folders.values.map(&:id))
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    def hide_inactive_folders(existing_folder_ids)
      info "Hiding inactive folders..."
      user_permissions = [{ user_id: username, permissions: FILE_PERMISSIONS },
                          { group_id: group, permissions: [] }]
      active_folders = @project_storages.pluck(:project_folder_id)

      (existing_folder_ids - active_folders).each do |file_id|
        Adapters::Input::SetPermissions.build(user_permissions:, file_id:).bind do |input_data|
          @commands[:set_permissions].call(auth_strategy:, input_data:).or { |error| log_adapter_error(error) }
        end
      end

      Success(:hide_inactive_folders)
    end

    def ensure_folders_exist(remote_folders)
      info "Ensuring that automatically managed project folders exist and are correctly named."
      id_folder_map = remote_folders.transform_keys(&:id)

      @project_storages.includes(:project).find_each do |project_storage|
        folder_id = project_storage.project_folder_id

        case id_folder_map[folder_id]
        when nil
          create_remote_folder(project_storage)
        when project_storage.managed_project_folder_path.chop
          Success()
        else
          rename_folder(folder_id, project_storage.managed_project_folder_name)
        end
      end

      Success(:setup_folders)
    end

    def rename_folder(location, new_name)
      info "Renaming project folder to #{new_name}"

      Adapters::Input::RenameFile.build(location:, new_name:).bind do |input_data|
        @commands[:rename_file].call(auth_strategy:, input_data:).alt_map do |error|
          add_error(
            :rename_project_folder, error,
            options: { current_path: location, project_folder_name: new_name }
          )
        end
      end
    end

    def create_remote_folder(project_storage)
      folder_name = project_storage.managed_project_folder_path

      input_data = Adapters::Input::CreateFolder.build(folder_name:, parent_location: "/").value_or do |error|
        add_validation_error(error, options: { folder_id: folder_name })
      end

      created_folder = @commands[:create_folder].call(auth_strategy:, input_data:).value_or do |error|
        add_error(:create_folder, error, options: { folder_name:, parent_location: "/" })
        return Failure()
      end

      audit_last_project_folder(project_storage, created_folder)
    end

    def audit_last_project_folder(project_storage, created_folder)
      ApplicationRecord.transaction do
        last_project_folder = LastProjectFolder.find_or_initialize_by(
          project_storage_id: project_storage.id, mode: project_storage.project_folder_mode
        )

        success = last_project_folder.update(origin_folder_id: created_folder.id) &&
                  last_project_folder.project_storage.update(project_folder_id: created_folder.id)

        raise ActiveRecord::Rollback unless success
      end

      Success(:create_folder)
    end

    def ensure_root_folder_permissions(root_folder_id)
      info "Setting needed permissions for user #{username} and group #{group} on the root team folder."
      permissions = [
        { user_id: username, permissions: FILE_PERMISSIONS },
        { group_id: group, permissions: [:read_files] }
      ]

      input_data = build_set_permissions_input_data(root_folder_id, permissions).value_or do |failure|
        add_validation_error(failure, options: { root_folder_id:, permissions: })
        return Failure()
      end

      @commands[:set_permissions].call(auth_strategy:, input_data:).alt_map do |error|
        add_error(:ensure_root_folder_permissions, error, options: { group:, username: })
      end
    end

    def remote_root_folder_map
      info "Retrieving already existing folders under #{group_folder}"

      input_data = Adapters::Input::FilePathToIdMap.build(folder: group_folder, depth: 1).value_or do |error|
        add_validation_error(error, options: { folder: group_folder })

        return Failure()
      end

      @commands[:file_path_to_id_map].call(auth_strategy:, input_data:).alt_map do |error|
        add_error(:remote_folders, error, options: { group_folder:, username: })
      end
    end

    def build_set_permissions_input_data(file_id, user_permissions)
      Adapters::Input::SetPermissions.build(file_id:, user_permissions:)
    end

    def auth_strategy
      @auth_strategy ||= Adapters::Registry["nextcloud.authentication.userless"].call
    end

    def setup_commands
      @commands = %w[nextcloud.commands.create_folder nextcloud.commands.rename_file nextcloud.commands.set_permissions
                     nextcloud.queries.file_path_to_id_map].each_with_object({}) do |key, hash|
        hash[key.split(".").last.to_sym] = Adapters::Registry[key].new(@storage)
      end
    end
  end
end

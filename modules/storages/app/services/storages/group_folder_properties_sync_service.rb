# frozen_string_literal: true

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

# TODO: Rename Class to NextcloudManagedFolderSync
#
module Storages
  class GroupFolderPropertiesSyncService
    using Peripherals::ServiceResultRefinements

    PERMISSIONS_MAP = {
      read_files: 1,
      write_files: 2,
      create_files: 4,
      delete_files: 8,
      share_files: 16
    }.freeze

    PERMISSIONS_KEYS = PERMISSIONS_MAP.keys.freeze
    ALL_PERMISSIONS = PERMISSIONS_MAP.values.sum
    NO_PERMISSIONS = 0

    def initialize(storage)
      @storage = storage
    end

    def call
      prepare_remote_folders and apply_permissions_to_folders
    end

    private

    # rubocop:disable Metrics/AbcSize
    def prepare_remote_folders
      remote_folders = remote_root_folder_properties.result_or do |error|
        error_msg = { command: 'nextcloud.file_ids',
                      folder: @storage.group_folder,
                      message: error.log_message,
                      data: { status: error.data.code, body: error.data.body } }.to_json

        raise error_msg if error.code == :error

        return OpenProject.logger.warn error_msg
      end

      ensure_root_folder_permissions.error_and do |error|
        error_msg = { command: 'nextcloud.set_permissions',
                      folder: @storage.group_folder,
                      message: error.log_message,
                      data: { status: error.data.code, body: error.data.body } }.to_json
        raise error_msg if error.code == :error

        return OpenProject.logger.warn(error_msg)
      end

      ensure_folders_exist(remote_folders) and hide_inactive_folders(remote_folders)
    end

    def apply_permissions_to_folders
      remote_admins = admin_client_tokens_scope.pluck(:origin_user_id)

      active_project_storages_scope.where.not(project_folder_id: nil).find_each do |project_storage|
        set_folders_permissions(remote_admins, project_storage)
      end

      add_remove_users_to_group
    end

    def add_remove_users_to_group
      remote_users = remote_group_users.result_or do |error|
        return OpenProject.logger.warn({ command: 'nextcloud.group_users',
                                         group: @storage.group,
                                         message: error.log_message,
                                         data: { status: error.data.code, body: error.data.body } }.to_json)
      end

      local_users = client_tokens_scope.order(:id).pluck(:origin_user_id)

      (remote_users - local_users - [@storage.username]).each do |user|
        remove_user_from_remote_group(user).result_or do |error|
          OpenProject.logger.warn({ command: 'nextcloud.remove_user_from_group',
                                    group: @storage.group,
                                    user:,
                                    message: error.log_message,
                                    data: { status: error.data.code, body: error.data.body } }.to_json)
        end
      end

      (local_users - remote_users - [@storage.username]).each do |user|
        add_user_to_remote_group(user).result_or do |error|
          OpenProject.logger.warn({ command: 'nextcloud.add_users_to_group',
                                    group: @storage.group,
                                    user:,
                                    message: error.log_message,
                                    data: { status: error.data.code, body: error.data.body } }.to_json)
        end
      end
    end

    def add_user_to_remote_group(user)
      Peripherals::Registry
        .resolve("commands.nextcloud.add_user_to_group")
        .call(storage: @storage, user:)
    end

    def remove_user_from_remote_group(user)
      Peripherals::Registry
        .resolve("commands.nextcloud.remove_user_from_group")
        .call(storage: @storage, user:)
    end

    def set_folders_permissions(remote_admins, project_storage)
      admin_permissions = remote_admins.to_set.map do |username|
        [username, ALL_PERMISSIONS]
      end.unshift([@storage.username, ALL_PERMISSIONS])

      users_permissions = project_tokens(project_storage).each_with_object({}) do |token, hash|
        permissions = token.user.all_permissions_for(project_storage.project)

        hash[token.origin_user_id] = PERMISSIONS_MAP.values_at(*(PERMISSIONS_KEYS & permissions)).sum
      end

      command_params = {
        path: project_storage.project_folder_path,
        permissions: {
          users: admin_permissions.to_h.merge(users_permissions),
          groups: { "#{@storage.group}": NO_PERMISSIONS }
        }
      }

      Peripherals::Registry
        .resolve("commands.nextcloud.set_permissions")
        .call(storage: @storage, **command_params)
        .result_or do |error|
        OpenProject.logger.warn({ command: 'nextcloud.set_permissions',
                                  folder: project_storage.project_folder_path,
                                  message: error.log_message,
                                  data: { status: error.data.code, body: error.data.body } }.to_json)
      end
    end

    def project_tokens(project_storage)
      project_tokens = client_tokens_scope.where.not(id: admin_client_tokens_scope).order(:id)

      if project_storage.project.public? && ProjectRole.non_member.permissions.intersect?(PERMISSIONS_KEYS)
        project_tokens
      else
        project_tokens.where(user: project_storage.project.users)
      end
    end

    def hide_inactive_folders(remote_folders)
      project_folder_ids = active_project_storages_scope.pluck(:project_folder_id).compact
      remote_folders.except("#{@storage.group_folder}/").each do |(path, attrs)|
        next if project_folder_ids.include?(attrs['fileid'])

        command_params = {
          path:,
          permissions: {
            users: { "#{@storage.username}": ALL_PERMISSIONS },
            groups: { "#{@storage.group}": NO_PERMISSIONS }
          }
        }

        Peripherals::Registry
          .resolve("commands.nextcloud.set_permissions")
          .call(storage: @storage, **command_params)
          .result_or do |error|
          OpenProject.logger.warn({ command: 'nextcloud.set_permissions',
                                    folder: path,
                                    message: error.log_message,
                                    data: { status: error.data.code, body: error.data.body } }.to_json)
        end
      end
    end

    def ensure_folders_exist(remote_folders)
      id_folder_map = remote_folders.to_h { |folder, properties| [properties['fileid'], folder] }

      active_project_storages_scope.map do |project_storage|
        next create_folder(project_storage) unless id_folder_map.key?(project_storage.project_folder_id)

        current_path = id_folder_map[project_storage.project_folder_id]
        if current_path == project_storage.project_folder_path
          project_storage.project_folder_id
        else
          rename_folder(project_storage, current_path)
            .result_or do |error|
            error_msg = { command: 'nextcloud.rename_file',
                          source: current_path,
                          target: project_storage.project_folder_path,
                          data: { status: error.data.code, body: error.data.body } }.to_json

            # we need to stop as this would mess with the other processes
            return OpenProject.logger.warn error_msg
          end
        end
      end
    end

    def rename_folder(project_storage, current_name)
      Peripherals::Registry
        .resolve("commands.nextcloud.rename_file")
        .call(storage: @storage, source: current_name, target: project_storage.project_folder_path)
    end

    def create_folder(project_storage)
      folder_path = project_storage.project_folder_path
      Peripherals::Registry
        .resolve("commands.nextcloud.create_folder")
        .call(storage: @storage, folder_path:)
        .result_or do |error|
        error_msg = { command: 'nextcloud.create_folder',
                      folder: folder_path,
                      data: { status: error.data.code, body: error.data.body } }.to_json

        return OpenProject.logger.warn(error_msg)
      end

      folder_id = Peripherals::Registry
                    .resolve('queries.nextcloud.file_ids')
                    .call(storage: @storage, path: folder_path)
                    .result_or do |error|
        return OpenProject.logger.warn({ command: 'nextcloud.file_ids',
                                         path:,
                                         message: error.log_message,
                                         data: { status: error.data.code, body: error.data.body } }.to_json)
      end

      project_storage.update(project_folder_id: folder_id.dig(folder_path, 'fileid'))
      project_storage.reload.project_folder_id
    end

    # rubocop:enable Metrics/AbcSize

    def ensure_root_folder_permissions
      command_params = {
        path: @storage.group_folder,
        permissions: {
          users: { @storage.username.to_sym => ALL_PERMISSIONS },
          groups: { @storage.group.to_sym => PERMISSIONS_MAP[:read_files] }
        }
      }

      Peripherals::Registry
        .resolve("commands.nextcloud.set_permissions")
        .call(storage: @storage, **command_params)
    end

    ### Base Queries/Commands
    def remote_root_folder_properties
      Peripherals::Registry
        .resolve("queries.nextcloud.file_ids")
        .call(storage: @storage, path: @storage.group_folder)
    end

    def remote_group_users
      Peripherals::Registry
        .resolve("queries.nextcloud.group_users")
        .call(storage: @storage, group: @storage.group)
    end

    ### Model Scopes
    def project_storage_scope
      @storage.project_storages.automatic.joins(:project)
    end

    def active_project_storages_scope
      project_storage_scope.where(project: { active: true })
    end

    def client_tokens_scope
      OAuthClientToken.where(oauth_client: @storage.oauth_client)
    end

    def admin_client_tokens_scope
      OAuthClientToken.where(oauth_client: @storage.oauth_client, user: User.admin.active)
    end
  end
end

# frozen_string_literal: true

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

module Storages
  class NextcloudGroupFolderPropertiesSyncService
    using Peripherals::ServiceResultRefinements

    extend ActiveModel::Naming
    extend ActiveModel::Translation

    PERMISSIONS_MAP = { read_files: 1, write_files: 2, create_files: 4, delete_files: 8, share_files: 16 }.freeze

    PERMISSIONS_KEYS = PERMISSIONS_MAP.keys.freeze
    ALL_PERMISSIONS = PERMISSIONS_MAP.values.sum
    NO_PERMISSIONS = 0

    include Injector["nextcloud.commands.create_folder", "nextcloud.commands.rename_file", "nextcloud.commands.set_permissions",
                     "nextcloud.queries.group_users", "nextcloud.queries.file_ids", "nextcloud.authentication.userless",
                     "nextcloud.commands.add_user_to_group", "nextcloud.commands.remove_user_from_group"]

    def self.i18n_scope = "services"

    def self.call(storage)
      new(storage).call
    end

    def read_attribute_for_validation(attr) = attr

    def initialize(storage, **)
      super(**)
      @storage = storage
      @result = ServiceResult.success(errors: ActiveModel::Errors.new(self))
    end

    def call
      with_logging do
        log_message "Starting AMPF Sync for Nextcloud Storage #{@storage.id}"
        prepare_remote_folders.on_failure { return _1 }
        apply_permissions_to_folders
      end
    end

    private

    # @param attribute [Symbol] attribute to which the error will be tied to
    # @param storage_error [Storages::StorageError] an StorageError instance
    # @param options [Hash<Symbol, Object>] optional extra parameters for the message generation
    # @return [ServiceResult]
    def add_error(attribute, storage_error, options: {})
      if storage_error == :error
        @result.errors.add(:base, storage_error, **options)
      else
        @result.errors.add(attribute, storage_error, **options)
      end
      @result
    end

    # @return [ServiceResult]
    def prepare_remote_folders
      remote_folders = remote_root_folder_properties.result_or do |error|
        format_and_log_error(error, { folder: @storage.group_folder })
        return add_error(:remote_folder_properties, error.code, options: { group: @storage.group }).fail!
      end

      ensure_root_folder_permissions.result_or do |error|
        format_and_log_error(error, { folder: @storage.group_folder })
        return add_error(:ensure_root_folder_permissions, error.code,
                         options: { group: @storage.group, username: @storage.username }).fail!
      end

      ensure_folders_exist(remote_folders).on_success { hide_inactive_folders(remote_folders) }
    end

    def apply_permissions_to_folders
      remote_admins = admin_client_tokens_scope.pluck(:origin_user_id)

      active_project_storages_scope.where.not(project_folder_id: nil).find_each do |project_storage|
        set_folders_permissions(remote_admins, project_storage)
      end

      add_remove_users_to_group

      ServiceResult.success
    end

    def add_remove_users_to_group
      remote_users = remote_group_users.result_or do |error|
        return format_and_log_error(error, group: @storage.group)
      end

      local_users = client_tokens_scope.order(:id).pluck(:origin_user_id)

      remove_users_from_remote_group(remote_users - local_users - [@storage.username])
      add_users_to_remote_group(local_users - remote_users - [@storage.username])
    end

    def add_users_to_remote_group(users_to_add)
      users_to_add.each do |user|
        add_user_to_group.call(storage: @storage, user:).error_and do |error|
          format_and_log_error(error, group: @storage.group, user:)
        end
      end
    end

    def remove_users_from_remote_group(users_to_remove)
      users_to_remove.each do |user|
        remove_user_from_group.call(storage: @storage, user:).error_and do |error|
          format_and_log_error(error, group: @storage.group, user:)
        end
      end
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
        path: project_storage.managed_project_folder_path,
        permissions: {
          users: admin_permissions.to_h.merge(users_permissions),
          groups: { "#{@storage.group}": NO_PERMISSIONS }
        }
      }

      set_permissions.call(storage: @storage, **command_params).result_or do |error|
        format_and_log_error(error, folder: project_storage.managed_project_folder_path)
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
      log_message "Hiding folders related to inactive projects"
      project_folder_ids = active_project_storages_scope.pluck(:project_folder_id).compact
      remote_folders.except("/#{@storage.group_folder}/").each do |(path, attrs)|
        next if project_folder_ids.include?(attrs["fileid"])

        log_message "Hiding project folder #{path}"
        command_params = {
          path:,
          permissions: {
            users: { "#{@storage.username}": ALL_PERMISSIONS },
            groups: { "#{@storage.group}": NO_PERMISSIONS }
          }
        }

        set_permissions.call(storage: @storage, **command_params).on_failure do |service_result|
          format_and_log_error(service_result.errors, folder: path, context: "hide_folder")
          add_error(:hide_inactive_folders, service_result.errors, options: { folder: path })
        end
      end
    end

    def ensure_folders_exist(remote_folders)
      log_message "Ensuring project folders exist and are correctly named."
      id_folder_map = remote_folders.to_h { |folder, properties| [properties["fileid"], folder] }

      active_project_storages_scope.includes(:project).map do |project_storage|
        unless id_folder_map.key?(project_storage.project_folder_id)
          log_message "#{project_storage.managed_project_folder_path} does not exist. Creating..."
          next create_folder_stuff(project_storage)
        end

        current_path = id_folder_map[project_storage.project_folder_id]
        if current_path != project_storage.managed_project_folder_path
          log_message "#{current_path} is misnamed. Renaming to #{project_storage.managed_project_folder_path}"
          target_folder_name = name_from_path(project_storage.managed_project_folder_path)
          rename_folder(project_storage.project_folder_id, target_folder_name).on_failure do |service_result|
            format_and_log_error(service_result.errors,
                                 folder_id: project_storage.project_folder_id,
                                 folder_name: target_folder_name)

            return add_error(:rename_folder, service_result.errors).fail!
          end
        end
      end

      # We processed every folder successfully
      ServiceResult.success
    end

    def name_from_path(path)
      path.split("/").last
    end

    def rename_folder(folder_id, folder_name)
      rename_file.call(storage: @storage, auth_strategy:, file_id: folder_id, name: folder_name)
    end

    def create_folder_stuff(project_storage)
      folder_name = project_storage.managed_project_folder_path
      parent_location = Peripherals::ParentFolder.new("/")

      created_folder = create_folder.call(storage: @storage, auth_strategy:, folder_name:, parent_location:)
                                            .result_or do |error|
        format_and_log_error(error, folder_name:)

        return add_error(:create_folder, error, options: { folder_name:, parent_location: })
      end

      project_folder_id = created_folder.id
      last_project_folder = LastProjectFolder
                              .find_by(project_storage_id: project_storage.id, mode: project_storage.project_folder_mode)

      audit_last_project_folder(last_project_folder, project_folder_id)
      project_storage.project_folder_id
    end

    def audit_last_project_folder(last_project_folder, project_folder_id)
      ApplicationRecord.transaction do
        last_project_folder.update!(origin_folder_id: project_folder_id)
        project_storage.update!(project_folder_id:)
        project_storage.project_folder_id
      end
    end

    def ensure_root_folder_permissions
      log_message "Setting base permissions for user #{@storage.username} on the #{@storage.group_folder} folder"
      command_params = {
        path: @storage.group_folder,
        permissions: {
          users: { @storage.username.to_sym => ALL_PERMISSIONS },
          groups: { @storage.group.to_sym => PERMISSIONS_MAP[:read_files] }
        }
      }

      set_permissions.call(storage: @storage, **command_params)
    end

    ### Base Queries/Commands
    def remote_root_folder_properties
      log_message "Retrieving already existing folders under #{@storage.group_folder}"
      file_ids.call(storage: @storage, path: @storage.group_folder)
    end

    def remote_group_users
      group_users.call(storage: @storage, group: @storage.group)
    end

    ### Model Scopes

    def active_project_storages_scope
      @storage.project_storages.active.automatic
    end

    def client_tokens_scope
      OAuthClientToken.where(oauth_client: @storage.oauth_client)
    end

    def auth_strategy
      @auth_strategy ||= userless.call
    end

    def admin_client_tokens_scope
      OAuthClientToken.where(oauth_client: @storage.oauth_client, user: User.admin.active)
    end

    # Logging

    def format_and_log_error(error, context = {})
      payload = error.data.payload
      data =
        case payload
        in { status: Integer }
          { status: payload.status, body: payload.body.to_s }
        else
          payload.to_s
        end

      error_message = context.merge({ command: error.data.source, message: error.log_message, data: })
      logger.error error_message
    end

    def log_message(message)
      logger.debug(message)
    end

    def with_logging(&)
      logger.tagged(self.class, "storage-#{@storage.id}", &)
    end

    def logger
      Rails.logger
    end
  end
end

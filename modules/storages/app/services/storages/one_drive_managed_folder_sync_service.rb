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
  class OneDriveManagedFolderSyncService
    using Peripherals::ServiceResultRefinements

    OP_PERMISSIONS = %i[read_files write_files create_files delete_files share_files].freeze

    def self.call(storage)
      new(storage).call
    end

    def initialize(storage)
      @storage = storage
    end

    def call
      return unless @storage.automatic_management_enabled?

      existing_remote_folders = remote_folders_map.on_failure { |failed_result| return failed_result }.result

      ensure_folders_exist(existing_remote_folders).on_success { hide_inactive_folders(existing_remote_folders) }
      apply_permission_to_folders
    end

    private

    def apply_permission_to_folders
      active_project_storages_scope.includes(:project).where.not(project_folder_id: nil).find_each do |project_storage|
        permissions = { read: [], write: admin_client_tokens_scope.pluck(:origin_user_id) }
        project_tokens(project_storage).each do |token|
          add_user_to_permission_list(permissions, token, project_storage.project)
        end

        set_permissions(project_storage.project_folder_id, permissions)
      end

      ServiceResult.success
    end

    def ensure_folders_exist(folder_map)
      active_project_storages_scope.includes(:project).find_each do |project_storage|
        next create_folder(project_storage) unless folder_map.key?(project_storage.project_folder_id)

        if folder_map[project_storage.project_folder_id] != project_storage.managed_project_folder_path
          rename_folder(project_storage.project_folder_id, project_storage.managed_project_folder_path)
        end
      end

      ServiceResult.success(result: 'folders processed')
    end

    def hide_inactive_folders(folder_map)
      project_folder_ids = active_project_storages_scope.pluck(:project_folder_id).compact
      (folder_map.keys - project_folder_ids).each do |item_id|
        Peripherals::Registry.resolve("one_drive.commands.set_permissions")
                             .call(storage: @storage, path: item_id, permissions: { write: [], read: [] })
                             .on_failure do |service_result|
          format_and_log_error(service_result.errors, folder: path, context: 'hide_folder')
        end
      end
    end

    def add_user_to_permission_list(permissions, token, project)
      op_user_permissions = token.user.all_permissions_for(project)

      if op_user_permissions.member?(:write_files)
        permissions[:write] << token.origin_user_id
      elsif op_user_permissions.member?(:read_files)
        permissions[:read] << token.origin_user_id
      end
    end

    def set_permissions(path, permissions)
      Peripherals::Registry.resolve("one_drive.commands.set_permissions")
                           .call(storage: @storage, path:, permissions:)
                           .result_or do |error|
        format_and_log_error(error, folder: path)
      end
    end

    def rename_folder(source, target)
      Peripherals::Registry
        .resolve('one_drive.commands.rename_file')
        .call(storage: @storage, source:, target:)
        .result_or { |error| format_and_log_error(error, source:, target:) }
    end

    def create_folder(project_storage)
      Peripherals::Registry
        .resolve('one_drive.commands.create_folder')
        .call(storage: @storage, folder_path: project_storage.managed_project_folder_path)
        .match(on_failure: ->(error) { format_and_log_error(error, folder_path: project_storage.managed_project_folder_path) },
               on_success: ->(folder_info) do
                 last_project_folder = ::Storages::LastProjectFolder
                                         .find_by(
                                           project_storage_id: project_storage.id,
                                           mode: project_storage.project_folder_mode
                                         )
                 ApplicationRecord.transaction do
                   last_project_folder.update!(origin_folder_id: folder_info.id)
                   project_storage.update!(project_folder_id: folder_info.id)
                 end
               end)
    end

    def remote_folders_map
      using_admin_token do |http|
        response = http.get("/v1.0/drives/#{@storage.drive_id}/root/children")

        if response.status == 200
          ServiceResult.success(result: filter_folders_from(response.json(symbolize_keys: true)))
        else
          errors = ::Storages::StorageError.new(code: response.status,
                                                data: ::Storages::StorageErrorData.new(
                                                  source: self.class, payload: response
                                                ))
          format_and_log_error(errors)
          ServiceResult.failure(result: :error, errors:)
        end
      end
    end

    def filter_folders_from(json)
      json.fetch(:value, []).each_with_object({}) do |item, hash|
        next unless item.key?(:folder)

        hash[item[:id]] = item[:name]
      end
    end

    def using_admin_token(&)
      Peripherals::StorageInteraction::OneDrive::Util.using_admin_token(@storage, &)
    end

    def project_tokens(project_storage)
      project_tokens = client_tokens_scope.where.not(id: admin_client_tokens_scope).order(:id)

      if project_storage.project.public? && ProjectRole.non_member.permissions.intersect?(OP_PERMISSIONS)
        project_tokens
      else
        project_tokens.where(user: project_storage.project.users)
      end
    end

    def active_project_storages_scope
      @storage.project_storages.active.automatic
    end

    def client_tokens_scope
      OAuthClientToken.where(oauth_client: @storage.oauth_client)
    end

    def admin_client_tokens_scope
      OAuthClientToken.where(oauth_client: @storage.oauth_client, user: User.admin.active)
    end

    def format_and_log_error(error, context = {})
      payload = error.data.payload
      data =
        case payload
        in { status: Integer }
          { status: payload.status, body: payload.body.to_s }
        else
          payload.error.to_s
        end

      error_message = context.merge({ command: error.data.source, message: error.log_message, data: })
      OpenProject.logger.warn error_message
    end
  end
end

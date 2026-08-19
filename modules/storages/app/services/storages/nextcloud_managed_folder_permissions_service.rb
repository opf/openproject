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
  class NextcloudManagedFolderPermissionsService < BaseService
    using Peripherals::ServiceResultRefinements

    FILE_PERMISSIONS = OpenProject::Storages::Engine.external_file_permissions

    class << self
      def i18n_key = "nextcloud_sync_service"

      def call(storage:, project_storages_scope: nil)
        new(storage:, project_storages_scope:).call
      end
    end

    delegate :group_user, :group, :username, to: :@storage, private: true

    def initialize(storage:, project_storages_scope: nil)
      super()
      @storage = storage
      @project_storages = project_storages_scope || storage.project_storages
      setup_commands
    end

    def call
      with_tagged_logger([self.class.name, "storage-#{@storage.id}"]) do
        apply_permissions_to_folders.bind { add_remove_users_to_group }
        @result
      end
    end

    private

    def apply_permissions_to_folders
      info "Setting permissions to project folders"
      remote_admins = admin_remote_identities.pluck(:origin_user_id)

      @project_storages.active.automatic.with_project_folder.order(:project_folder_id).find_each do |project_storage|
        set_folder_permissions(remote_admins, project_storage)
      end

      Success(:folder_permissions)
    end

    def add_remove_users_to_group
      info "Updating user access on automatically managed project folders"
      remote_users = remote_group_users.value_or { return Failure() }

      local_users = remote_identities.order(:id).pluck(:origin_user_id)

      remove_users_from_remote_group(remote_users - local_users - [username])
      add_users_to_remote_group(local_users - remote_users - [username])
    end

    def add_users_to_remote_group(users_to_add)
      users_to_add.each do |user|
        input_data = Adapters::Input::AddUserToGroup.build(group:, user:).value_or do |error|
          next add_validation_error(error)
        end

        @commands[:add_user_to_group].call(auth_strategy:, input_data:).or do |error|
          add_error(:add_user_to_group, error, options: { user:, group: })
        end
      end
    end

    def remove_users_from_remote_group(users_to_remove)
      users_to_remove.each do |user|
        input_data = Adapters::Input::RemoveUserFromGroup.build(group:, user:).value_or do |error|
          add_validation_error(error, options: { user:, group: })
          next
        end

        @commands[:remove_user_from_group].call(auth_strategy:, input_data:).or do |error|
          add_error(:remove_user_from_group, error, options: { user:, group:, reason: error.code })
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def set_folder_permissions(remote_admins, project_storage)
      project_folder_id = project_storage.project_folder_id

      if project_folder_id_collision?(project_storage)
        return add_error(:set_folder_permission, collision_error, options: { folder: project_folder_id })
      end

      admin_permissions = remote_admins.to_set.map { |username| { user_id: username, permissions: FILE_PERMISSIONS } }
      base_permissions = base_remote_permissions(admin_permissions)

      users_permissions = project_remote_identities(project_storage).map do |identity|
        { user_id: identity.origin_user_id,
          permissions: identity.user.all_permissions_for(project_storage.project) & FILE_PERMISSIONS }
      end

      permissions = base_permissions + users_permissions

      input_data = build_set_permissions_input_data(project_folder_id, permissions).value_or do |failure|
        log_validation_error(failure, project_folder_id:, permissions:)
      end

      @commands[:set_permissions].call(auth_strategy:, input_data:).or do |error|
        add_error(:set_folder_permission, error, options: { folder: project_folder_id })
      end
    end
    # rubocop:enable Metrics/AbcSize

    def base_remote_permissions(admin_permissions)
      [{ user_id: @storage.username, permissions: FILE_PERMISSIONS },
       { group_id: @storage.group, permissions: [] }] + admin_permissions
    end

    def project_remote_identities(project_storage)
      user_remote_identities = remote_identities.where.not(id: admin_remote_identities).order(:id)

      if project_storage.project.public? && ProjectRole.non_member.permissions.intersect?(FILE_PERMISSIONS)
        user_remote_identities
      else
        user_remote_identities.where(user: project_storage.project.users)
      end
    end

    def build_set_permissions_input_data(file_id, user_permissions)
      Adapters::Input::SetPermissions.build(file_id:, user_permissions:)
    end

    def remote_group_users
      info "Retrieving users that are part of the #{group} group"
      input_data = Adapters::Input::GroupUsers
                     .build(group:)
                     .value_or { return Failure(add_validation_error(it, options: { group: })) }

      @commands[:group_users].call(auth_strategy:, input_data:).or do |error|
        Failure(add_error(:group_users, error, options: { group: group }))
      end
    end

    # We refuse to overwrite an ACL when another project_storage on the same storage holds the same folder id
    # (defense in depth in case the contract check is bypassed or a folder id collision is written directly to the DB)
    def project_folder_id_collision?(project_storage)
      ::Storages::ProjectStorage
        .where(storage_id: project_storage.storage_id, project_folder_id: project_storage.project_folder_id)
        .where.not(id: project_storage.id)
        .exists?
    end

    def collision_error
      ::Storages::Adapters::Results::Error.new(source: self.class, code: :folder_id_collision)
    end

    ### Model Scopes

    def remote_identities
      RemoteIdentity.includes(:user).where(integration: @storage)
    end

    def admin_remote_identities
      remote_identities.where(user: User.admin.active)
    end

    def auth_strategy
      @auth_strategy ||= Adapters::Registry.resolve("nextcloud.authentication.userless").call
    end

    def setup_commands
      @commands = %w[nextcloud.commands.set_permissions nextcloud.commands.remove_user_from_group
                     nextcloud.commands.add_user_to_group nextcloud.queries.group_users].to_h do |key|
        [key.split(".").last.to_sym, Adapters::Registry[key].new(@storage)]
      end
    end
  end
end

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

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Services
          class SetPermissionsOnManagedFoldersService < BaseService
            using Peripherals::ServiceResultRefinements

            OP_PERMISSIONS = %i[read_files write_files create_files delete_files share_files].freeze

            def self.i18n_key = "sharepoint_sync_service"

            class << self
              def call(storage:, project_storages_scope: nil)
                new(storage:, project_storages_scope:).call
              end
            end

            def initialize(storage:, project_storages_scope: nil)
              super()
              @storage = storage
              @project_storages = (project_storages_scope || @storage.project_storages).active.automatic
            end

            def call
              with_tagged_logger([self.class.name, "storage-#{@storage.id}"]) do
                apply_permission_to_folders

                @result
              end
            end

            private

            # rubocop:disable Metrics/AbcSize
            def apply_permission_to_folders
              info "Setting permissions to project folders"
              @project_storages.includes(:project).with_project_folder.find_each do |project_storage|
                permissions = admin_remote_identities_scope.pluck(:origin_user_id).map do |origin_user_id|
                  { user_id: origin_user_id, permissions: [:write_files] }
                end

                project_remote_identities(project_storage).each do |identity|
                  add_user_to_permission_list(permissions, identity, project_storage.project)
                end

                info "Setting permissions for #{project_storage.managed_project_folder_name}: #{permissions}"

                project_folder_id = project_storage.project_folder_id
                build_permissions_input_data(project_folder_id, permissions)
                  .either(
                    ->(input_data) { set_permissions.call(storage: @storage, auth_strategy:, input_data:) },
                    ->(failure) { log_validation_error(failure, project_folder_id:, permissions:) }
                  )
              end
            end

            # rubocop:enable Metrics/AbcSize

            def add_user_to_permission_list(permissions, identity, project)
              op_user_permissions = identity.user.all_permissions_for(project)

              if op_user_permissions.member?(:write_files)
                permissions << { user_id: identity.origin_user_id, permissions: [:write_files] }
              elsif op_user_permissions.member?(:read_files)
                permissions << { user_id: identity.origin_user_id, permissions: [:read_files] }
              end
            end

            def project_remote_identities(project_storage)
              project_remote_identities = client_remote_identities_scope.where.not(id: admin_remote_identities_scope).order(:id)

              if project_storage.project.public? && ProjectRole.non_member.permissions.intersect?(OP_PERMISSIONS)
                project_remote_identities
              else
                project_remote_identities.where(user: project_storage.project.users)
              end
            end

            def client_remote_identities_scope
              RemoteIdentity.includes(:user).where(integration: @storage)
            end

            def admin_remote_identities_scope
              client_remote_identities_scope.where(user: User.admin.active)
            end

            def set_permissions = Adapters::Registry.resolve("sharepoint.commands.set_permissions")
            def auth_strategy = Adapters::Registry.resolve("sharepoint.authentication.userless").call

            def build_permissions_input_data(file_id, user_permissions)
              Adapters::Input::SetPermissions.build(file_id:, user_permissions:)
            end
          end
        end
      end
    end
  end
end

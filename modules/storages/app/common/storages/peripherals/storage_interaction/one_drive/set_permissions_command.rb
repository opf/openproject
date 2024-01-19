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
  module Peripherals
    module StorageInteraction
      module OneDrive
        class SetPermissionsCommand
          using ServiceResultRefinements

          def self.call(storage:, path:, permissions:)
            new(storage).call(path:, permissions:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(path:, permissions:)
            # This could be broken down into:
            # 1. Get Permission IDs
            # 2. Apply Permission Changes
            # 2.1 Create Permissions
            # 2.2 Delete Permissions
            # 2.3 Re-create Permissions

            item_exists?(path).on_failure { |failed_result| return failed_result }

            current_permissions = get_permissions(path)
                                    .on_failure { |failed_result| return failed_result }
                                    .result

            permission_ids = extract_permission_ids(current_permissions[:value])

            permissions.each_pair do |permission, user_ids|
              apply_permission_changes(permission, user_ids, permission_ids[permission], path)
            end
          end

          private

          def item_exists?(item_id)
            Util.using_admin_token(@storage) { |http| handle_response(http.get(item_path(item_id))) }
          end

          def get_permissions(path)
            Util.using_admin_token(@storage) { |http| handle_response(http.get(permissions_path(path))) }
          end

          def apply_permission_changes(role, permissions, permission_set_id, item_id)
            return delete_permissions(permission_set_id, item_id) if permissions.empty? && permission_set_id
            return create_permissions(role, permissions, item_id) if permissions.any? && permission_set_id.nil?

            update_permissions(role, permissions, permission_set_id, item_id)
          end

          def update_permissions(role, permissions, permission_set_id, item_id)
            delete_permissions(permission_set_id, item_id).on_success { create_permissions(role, permissions, item_id) }
          end

          def create_permissions(role, permissions, item_id)
            drive_recipients = permissions.map { |id| { objectId: id } }
            Util.using_admin_token(@storage) do |http|
              response = http.post(invite_path(item_id),
                                   body: {
                                     requireSignIn: true,
                                     sendInvitation: false,
                                     roles: [role],
                                     recipients: drive_recipients
                                   }.to_json)

              handle_response(response)
            end
          end

          def delete_permissions(permission_set_id, item_id)
            Util.using_admin_token(@storage) do |http|
              handle_response(http.delete(permission_path(item_id, permission_set_id)))
            end
          end

          # This will grab the first write or read permission.
          # If the folder is setup correctly this should be enough
          def extract_permission_ids(permission_set)
            write_permission = permission_set.find(-> { {} }) { |hash| hash[:roles].first == 'write' }[:id]
            read_permission = permission_set.find(-> { {} }) { |hash| hash[:roles].first == 'read' }[:id]

            { read: read_permission, write: write_permission }
          end

          def handle_response(response)
            data = ::Storages::StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200 }
              ServiceResult.success(result: response.json(symbolize_keys: true))
            in { status: 204 }
              ServiceResult.success
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized, errors: ::Storages::StorageError.new(code: :unauthorized, data:))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden, errors: ::Storages::StorageError.new(code: :forbidden, data:))
            in { status: 404 }
              ServiceResult.failure(result: :not_found, errors: ::Storages::StorageError.new(code: :not_found, data:))
            else
              ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error, data:))
            end
          end

          def permission_path(item_id, permission_id)
            "#{permissions_path(item_id)}/#{permission_id}"
          end

          def permissions_path(item_id)
            "#{item_path(item_id)}/permissions"
          end

          def invite_path(item_id)
            "#{item_path(item_id)}/invite"
          end

          def item_path(item_id)
            "/v1.0/drives/#{@storage.drive_id}/items/#{item_id}"
          end
        end
      end
    end
  end
end

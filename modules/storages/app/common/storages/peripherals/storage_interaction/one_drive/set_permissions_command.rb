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

          PermissionUpdateData = Data.define(:role, :permission_ids, :user_ids, :drive_item_id) do
            def create? = permission_ids.empty? && user_ids.any?

            def delete? = permission_ids.any? && user_ids.empty?

            def update? = permission_ids.any? && user_ids.any?
          end

          def self.call(storage:, path:, permissions:)
            new(storage).call(path:, permissions:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(path:, permissions:)
            item_exists?(path).on_failure { |failed_result| return failed_result }

            current_permissions = get_permissions(path)
                                    .on_failure { |failed_result| return failed_result }
                                    .result

            permission_ids = extract_permission_ids(current_permissions[:value])

            permissions.each_pair do |role, user_ids|
              apply_permission_changes(
                PermissionUpdateData.new(role:, user_ids:, permission_ids: permission_ids[role], drive_item_id: path)
              )
            end

            ServiceResult.success
          end

          private

          def item_exists?(item_id)
            Util.using_admin_token(@storage) { |http| handle_response(http.get(item_path(item_id))) }
          end

          def get_permissions(path)
            Util.using_admin_token(@storage) { |http| handle_response(http.get(permissions_path(path))) }
          end

          def apply_permission_changes(update_data)
            return delete_permissions(update_data) if update_data.delete?
            return create_permissions(update_data) if update_data.create?

            update_permissions(update_data) if update_data.update?
          end

          def update_permissions(update_data)
            delete_permissions(update_data)
            create_permissions(update_data)
          end

          def create_permissions(update_data)
            drive_recipients = update_data.user_ids.map { |id| { objectId: id } }

            Util.using_admin_token(@storage) do |http|
              response = http.post(invite_path(update_data.drive_item_id),
                                   body: {
                                     requireSignIn: true,
                                     sendInvitation: false,
                                     roles: [update_data.role],
                                     recipients: drive_recipients
                                   }.to_json)

              handle_response(response).result_or { |error| log_error(error) }
            end
          end

          def delete_permissions(update_data)
            Util.using_admin_token(@storage) do |http|
              update_data.permission_ids.each do |permission_id|
                handle_response(
                  http.delete(permission_path(update_data.drive_item_id, permission_id))
                ).result_or { |error| log_error(error) }
              end
            end
          end

          def extract_permission_ids(permission_set)
            filter = ->(role, permission) do
              next unless permission[:roles].member?(role)

              permission[:id]
            end.curry

            write_permissions = permission_set.filter_map(&filter.call("write"))
            read_permissions = permission_set.filter_map(&filter.call("read"))

            { read: read_permissions, write: write_permissions }
          end

          # rubocop:disable Metrics/AbcSize
          def handle_response(response)
            case response
            in { status: 200 }
              ServiceResult.success(result: response.json(symbolize_keys: true))
            in { status: 204 }
              ServiceResult.success(result: response)
            in { status: 400 }
              ServiceResult.failure(result: :bad_request,
                                    errors: Util.storage_error(response:, code: :bad_request, source: self.class))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(response:, code: :unauthorized, source: self.class))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden,
                                    errors: Util.storage_error(response:, code: :forbidden, source: self.class))
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: Util.storage_error(response:, code: :not_found, source: self.class))
            else
              ServiceResult.failure(result: :error,
                                    errors: Util.storage_error(response:, code: :error, source: self.class))
            end
          end

          # rubocop:enable Metrics/AbcSize

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
            UrlBuilder.url(Util.drive_base_uri(@storage), "/items", item_id)
          end

          def log_error(error)
            payload = error.data.payload
            OpenProject.logger.warn(
              command: error.data.source,
              message: error.log_message,
              data: {
                status: payload.try(:status),
                body: (payload.try(:body) || payload).to_s
              }
            )
          end
        end
      end
    end
  end
end

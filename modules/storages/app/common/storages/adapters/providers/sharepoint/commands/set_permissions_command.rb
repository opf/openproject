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
        module Commands
          class SetPermissionsCommand < Base
            include Dry::Monads::Do.for(:call)

            PermissionUpdateData = ::Data.define(:role, :permission_ids, :user_ids, :drive_id, :item_id) do
              def create? = permission_ids.empty? && user_ids.any?

              def delete? = permission_ids.any? && user_ids.empty?

              def update? = permission_ids.any? && user_ids.any?
            end

            PermissionFilter = lambda do |role, permission|
              next unless permission[:roles].member?(role)

              permission[:id]
            end.curry

            private_constant :PermissionFilter, :PermissionUpdateData

            # @param auth_strategy [AuthenticationStrategy] The authentication strategy to use.
            # @param input_data [Inputs::SetPermissions] The data needed for setting permissions, containing the file id
            # and the permissions for an array of users.
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                Authentication[auth_strategy].call(storage: @storage) do |http|
                  info "Checking if file #{input_data.file_id} exists"
                  split_identifier(input_data.file_id) => { drive_id:, location: item_id }
                  yield drive_item_query.call(http:, drive_id:, item_id:)

                  info "Getting current permissions for #{item_id}"
                  current_permissions = yield(
                    handle_response(http.get(permissions_path(drive_id, item_id))).fmap do |result|
                      extract_permission_ids(result[:value])
                    end
                  )

                  info "Read and write permissions found: #{current_permissions}"

                  role_to_user_map(input_data).each_pair do |role, user_ids|
                    update_data = PermissionUpdateData.new(role:,
                                                           user_ids:,
                                                           permission_ids: current_permissions[role],
                                                           drive_id:,
                                                           item_id:)

                    delete_permissions(update_data, http) if update_data.delete?
                    create_permissions(update_data, http) if update_data.create?
                    update_permissions(update_data, http) if update_data.update?
                  end

                  Success()
                end
              end
            end

            private

            def drive_item_query
              @drive_item_query ||= Queries::Internal::DriveItemQuery.new(@storage)
            end

            def role_to_user_map(input_data)
              input_data.user_permissions.each_with_object({ read: [], write: [] }) do |user_permission_set, map|
                if user_permission_set[:permissions].include?(:write_files)
                  map[:write] << user_permission_set[:user_id]
                elsif user_permission_set[:permissions].include?(:read_files)
                  map[:read] << user_permission_set[:user_id]
                end
              end
            end

            def update_permissions(update_data, http)
              info "Updating permissions on #{update_data.item_id}"
              delete_permissions(update_data, http)
              create_permissions(update_data, http)
            end

            def create_permissions(update_data, http)
              drive_recipients = update_data.user_ids.map { |id| { objectId: id } }

              info "Creating #{update_data.role} permissions on #{update_data.item_id} for #{drive_recipients}"
              response = http.post(invite_path(update_data.drive_id, update_data.item_id),
                                   json: {
                                     requireSignIn: true,
                                     sendInvitation: false,
                                     roles: [update_data.role],
                                     recipients: drive_recipients
                                   })

              handle_response(response).or { |error| log_storage_error(error) }
            end

            def delete_permissions(update_data, http)
              info "Removing permissions on #{update_data.item_id}"

              update_data.permission_ids.each do |permission_id|
                handle_response(
                  http.delete(permission_path(update_data.drive_id, update_data.item_id, permission_id))
                ).or { |error| log_storage_error(error) }
              end
            end

            def extract_permission_ids(permission_set)
              write_permissions = permission_set.filter_map(&PermissionFilter.call("write"))
              read_permissions = permission_set.filter_map(&PermissionFilter.call("read"))

              { read: read_permissions, write: write_permissions }
            end

            def handle_response(response)
              error = Results::Error.new(payload: response, source: self.class)

              case response
              in { status: 200 }
                Success(response.json(symbolize_keys: true))
              in { status: 204 }
                Success(result: response)
              in { status: 400 }
                Failure(error.with(code: :bad_request))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 403 }
                Failure(error.with(code: :forbidden))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              else
                Failure(error.with(code: :error))
              end
            end

            def permission_path(drive_id, item_id, permission_id) = "#{permissions_path(drive_id, item_id)}/#{permission_id}"

            def permissions_path(drive_id, item_id) = "#{item_path(drive_id, item_id)}/permissions"

            def invite_path(drive_id, item_id) = "#{item_path(drive_id, item_id)}/invite"

            def item_path(drive_id, item_id)
              UrlBuilder.url(base_uri, "/v1.0/drives", drive_id, "/items", item_id)
            end
          end
        end
      end
    end
  end
end

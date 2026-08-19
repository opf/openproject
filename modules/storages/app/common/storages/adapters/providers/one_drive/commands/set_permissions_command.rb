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
      module OneDrive
        module Commands
          class SetPermissionsCommand < Base
            include Dry::Monads::Do.for(:call)

            PermissionUpdateData = ::Data.define(:role, :permission_ids, :user_ids, :drive_item_id) do
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
                  item = input_data.file_id
                  yield item_exists?(http, item)

                  current_permissions = yield get_current_permissions(http, item)
                  info "Read and write permissions found: #{current_permissions}"

                  role_to_user_map(input_data).each_pair do |role, user_ids|
                    apply_permission_changes(
                      PermissionUpdateData.new(role:,
                                               user_ids:,
                                               permission_ids: current_permissions[role],
                                               drive_item_id: item),
                      http
                    )
                  end

                  Success()
                end
              end
            end

            private

            def role_to_user_map(input_data)
              input_data.user_permissions
                        .each_with_object({ read: [], write: [] }) do |user_permission_set, map|
                if user_permission_set[:permissions].include?(:write_files)
                  map[:write] << user_permission_set[:user_id]
                elsif user_permission_set[:permissions].include?(:read_files)
                  map[:read] << user_permission_set[:user_id]
                end
              end
            end

            def item_exists?(http, item_id)
              info "Checking if folder #{item_id} exists"
              handle_response(http.get(item_path(item_id)))
            end

            def get_current_permissions(http, path)
              info "Getting current permissions for #{path}"
              handle_response(http.get(permissions_path(path))).fmap { |result| extract_permission_ids(result[:value]) }
            end

            def apply_permission_changes(update_data, http)
              return delete_permissions(update_data, http) if update_data.delete?
              return create_permissions(update_data, http) if update_data.create?

              update_permissions(update_data, http) if update_data.update?
            end

            def update_permissions(update_data, http)
              info "Updating permissions on #{update_data.drive_item_id}"
              delete_permissions(update_data, http)
              create_permissions(update_data, http)
            end

            def create_permissions(update_data, http)
              drive_recipients = update_data.user_ids.map { |id| { objectId: id } }

              info "Creating #{update_data.role} permissions on #{update_data.drive_item_id} for #{drive_recipients}"
              response = http.post(invite_path(update_data.drive_item_id),
                                   json: {
                                     requireSignIn: true,
                                     sendInvitation: false,
                                     roles: [update_data.role],
                                     recipients: drive_recipients
                                   })

              handle_response(response).or { |error| log_storage_error(error) }
            end

            def delete_permissions(update_data, http)
              info "Removing permissions on #{update_data.drive_item_id}"

              update_data.permission_ids.each do |permission_id|
                handle_response(
                  http.delete(permission_path(update_data.drive_item_id, permission_id))
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

            def permission_path(item_id, permission_id) = "#{permissions_path(item_id)}/#{permission_id}"

            def permissions_path(item_id) = "#{item_path(item_id)}/permissions"

            def invite_path(item_id) = "#{item_path(item_id)}/invite"

            def item_path(item_id)
              UrlBuilder.url(base_uri, "/items", item_id)
            end
          end
        end
      end
    end
  end
end

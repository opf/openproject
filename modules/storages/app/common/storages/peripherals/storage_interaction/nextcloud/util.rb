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
  module Peripherals
    module StorageInteraction
      module Nextcloud
        module Util
          using ServiceResultRefinements

          class << self
            def ocs_api_request
              { headers: { "OCS-APIRequest" => "true" } }
            end

            def accept_json
              { headers: { "Accept" => "application/json" } }
            end

            def webdav_request_with_depth(number)
              { headers: { "Depth" => number } }
            end

            def storage_error(response:, code:, source:, log_message: nil)
              # Some errors, like timeouts, aren't json responses so we need to adapt
              data = StorageErrorData.new(source:, payload: response.to_s)

              StorageError.new(code:, data:, log_message:)
            end

            def error(code, log_message = nil, data = nil)
              ServiceResult.failure(
                result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
                errors: StorageError.new(code:, log_message:, data:)
              )
            end

            def token(user:, configuration:, &)
              connection_manager = OAuthClients::ConnectionManager.new(user:, configuration:)
              connection_manager.get_access_token.match(
                on_success: lambda do |token|
                  connection_manager.request_with_token_refresh(token) { yield token }
                end,
                on_failure: lambda do |_|
                  error(:unauthorized,
                        "Query could not be created! No access token found!",
                        StorageErrorData.new(source: connection_manager))
                end
              )
            end

            def error_text_from_response(response)
              response.xml.xpath("//s:message").text
            end

            def origin_user_id(caller:, storage:, auth_strategy:)
              case auth_strategy.key
              when :basic_auth
                ServiceResult.success(result: storage.username)
              when :oauth_user_token
                origin_user_id = RemoteIdentity.where(user_id: auth_strategy.user, oauth_client: storage.oauth_client)
                                               .pick(:origin_user_id)
                if origin_user_id.present?
                  ServiceResult.success(result: origin_user_id)
                else
                  failure(code: :error,
                          data: StorageErrorData.new(source: caller),
                          log_message:
                            "No origin user ID or user token found. Cannot execute query without user context.")
                end
              else
                failure(code: :error,
                        data: StorageErrorData.new(source: caller),
                        log_message: "No authentication strategy with user context found. " \
                                     "Cannot execute query without user context.")
              end
            end

            def error_data_from_response(caller:, response:)
              payload = if response.respond_to?(:content_type)
                          case response.content_type.mime_type
                          when "application/json"
                            response.json
                          when "text/xml", "application/xml"
                            response.xml
                          else
                            response.body.to_s
                          end
                        else
                          response.to_s
                        end

              StorageErrorData.new(source: caller, payload:)
            end

            def failure(code:, data:, log_message:)
              ServiceResult.failure(result: code, errors: StorageError.new(code:, data:, log_message:))
            end

            def storage_file_from_file_info(storage_file_info)
              StorageFile.new(
                id: storage_file_info.id,
                name: storage_file_info.name,
                size: storage_file_info.size,
                mime_type: storage_file_info.mime_type,
                created_at: storage_file_info.created_at,
                last_modified_at: storage_file_info.last_modified_at,
                created_by_name: storage_file_info.owner_name,
                last_modified_by_name: storage_file_info.last_modified_by_name,
                location: storage_file_info.location,
                permissions: storage_file_info.permissions
              )
            end
          end
        end
      end
    end
  end
end

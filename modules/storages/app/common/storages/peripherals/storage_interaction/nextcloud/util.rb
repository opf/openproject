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
      module Nextcloud
        module Util
          using ServiceResultRefinements

          class << self
            def escape_path(path)
              escaped_path = path.split("/").map { |i| CGI.escapeURIComponent(i) }.join("/")
              escaped_path << "/" if path[-1] == "/"
              escaped_path
            end

            def ocs_api_request
              { headers: { "OCS-APIRequest" => "true" } }
            end

            def accept_json
              { headers: { "Accept" => "application/json" } }
            end

            def webdav_request_with_depth(number)
              { headers: { "Depth" => number } }
            end

            def error(code, log_message = nil, data = nil)
              ServiceResult.failure(
                result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
                errors: StorageError.new(code:, log_message:, data:)
              )
            end

            def join_uri_path(uri, *)
              # We use `File.join` to ensure single `/` in between every part. This API will break if executed on a
              # Windows context, as it used `\` as file separators. But we anticipate that OpenProject
              # Server is not run on a Windows context.
              # URI::join cannot be used, as it behaves very different for the path parts depending on trailing slashes.
              File.join(uri.to_s, *)
            end

            def token(user:, configuration:, &)
              connection_manager = OAuthClients::ConnectionManager.new(user:, configuration:)
              connection_manager.get_access_token.match(
                on_success: ->(token) do
                  connection_manager.request_with_token_refresh(token) { yield token }
                end,
                on_failure: ->(_) do
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
                origin_user_id = OAuthClientToken.where(user_id: auth_strategy.user, oauth_client: storage.oauth_client)
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
              payload =
                case response.content_type.mime_type
                when "application/json"
                  response.json
                when "text/xml", "application/xml"
                  response.xml
                else
                  response.body.to_s
                end

              StorageErrorData.new(source: caller, payload:)
            end

            def failure(code:, data:, log_message:)
              ServiceResult.failure(result: code, errors: StorageError.new(code:, data:, log_message:))
            end
          end
        end
      end
    end
  end
end

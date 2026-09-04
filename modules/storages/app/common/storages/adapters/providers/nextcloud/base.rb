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
      module Nextcloud
        class Base
          include TaggedLogging
          include Dry::Monads::Result(SimpleError)

          def self.call(storage:, auth_strategy:, input_data:)
            new(storage).call(auth_strategy:, input_data:)
          end

          def initialize(storage)
            @storage = storage
          end

          private

          def ocs_api_request_headers = { headers: { "OCS-APIRequest" => "true" } }
          def depth_header(depth) = { headers: { "Depth" => depth.to_s } }

          def origin_user_id(auth_strategy:)
            error = SimpleError.new(source: self.class, code: :error)

            auth_strategy.bind do |strategy|
              case strategy.key
              when :basic_auth
                Success(@storage.username)
              when :oauth_user_token, :sso_user_token
                fetch_remote_identity(strategy.user, strategy.key)
              else
                Failure(
                  error.with(
                    payload: "authentication strategy with user context found. Cannot execute query without user context."
                  )
                )
              end
            end
          end

          def fetch_remote_identity(user, auth_key)
            integration = auth_key == :sso_user_token ? user.authentication_provider : @storage.oauth_client
            remote_id = RemoteIdentity.of_user_and_client(user, integration, @storage)

            if remote_id.present?
              Success(remote_id.origin_user_id)
            else
              Failure(error.with(payload: "No origin user ID or user token found. Cannot execute query without user context."))
            end
          end

          # Parses a response body as JSON. Nextcloud does not always answer in the requested format: OCS responses
          # rendered outside of the integration app (e.g. when it is disabled) fall back to XML, and reverse proxies
          # may answer with an HTML page. Those bodies make HTTPX raise, which would escape the adapter contract.
          # @return [Dry::Result]
          def parse_json(response, error)
            Success(response.json(symbolize_keys: true))
          rescue HTTPX::Error, MultiJSON::ParseError
            Failure(error.with(code: :invalid_response, payload: response))
          end

          # Validates the OCS Meta Statuscode for fatal errors (i.e. unexpected server-side errors). Client-side errors,
          # such as a 404 File Not Found do not cause an error.
          # @return [Dry::Result]
          def fail_on_ocs_error(json, error)
            if json_fetch(json, :ocs, :meta, :statuscode) < 500
              Success(json)
            else
              Failure(error.with(code: :error))
            end
          end

          def json_fetch(json, *path)
            current_path = []
            path.inject(json) do |j, key|
              if j.is_a?(Hash)
                current_path << key
                j.fetch(key) { raise "Could not find JSON path #{current_path.join('.')} in response (wanted #{path.join('.')})" }
              else
                raise "Object at JSON path #{current_path.join('.')} was expected to be a hash, " \
                      "but got #{j.class} (wanted #{path.join('.')})"
              end
            end
          end
        end
      end
    end
  end
end

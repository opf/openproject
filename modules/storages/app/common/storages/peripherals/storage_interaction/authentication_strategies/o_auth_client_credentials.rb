# frozen_string_literal:true

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
      module AuthenticationStrategies
        class OAuthClientCredentials
          def self.strategy
            Strategy.new(:oauth_client_credentials)
          end

          def call(storage:, http_options: {}, &)
            config = storage.oauth_configuration.to_httpx_oauth_config

            return build_failure(storage) unless config.valid?

            create_http_and_yield(issuer: config.issuer,
                                  client_id: config.client_id,
                                  client_secret: config.client_secret,
                                  scope: config.scope,
                                  http_options:,
                                  &)
          end

          private

          def create_http_and_yield(issuer:, client_id:, client_secret:, scope:, http_options:)
            begin
              http = OpenProject.httpx
                                .oauth_auth(issuer:,
                                            client_id:,
                                            client_secret:,
                                            scope:,
                                            token_endpoint_auth_method: "client_secret_post")
                                .with_access_token
                                .with(http_options)
            rescue HTTPX::HTTPError => e
              data = ::Storages::StorageErrorData.new(source: self.class, payload: e.response.json)
              return Failures::Builder.call(code: :unauthorized,
                                            log_message: "Error while fetching OAuth access token.",
                                            data:)
            end

            yield http
          end

          def build_failure(storage)
            log_message = "Cannot authenticate storage with client credential oauth flow. Storage not configured."
            data = ::Storages::StorageErrorData.new(source: self.class, payload: storage)
            Failures::Builder.call(code: :error, log_message:, data:)
          end
        end
      end
    end
  end
end

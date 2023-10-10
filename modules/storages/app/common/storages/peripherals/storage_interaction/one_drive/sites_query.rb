# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
        class SitesQuery
          def self.call(storage:)
            authentication = Storages::Authentication::Strategies::AccessTokenStrategy.new(user, storage.oauth_configuration)
            new(storage).call(authentication:)
          end

          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def call(authentication:)
            authentication.with_credential do |credential|
              request_sites(credential)
            end
          end

          private

          def request_sites(credential)
            response_data = Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
              http.get(
                sites_uri_path,
                { 'Authorization' => credential.authorization_header }
              )
            end

            handle_responses(response_data)
          end

          def sites_uri_path
            "/v1.0/sites"
          end

          def handle_responses(response)
            json = MultiJson.load(response.body, symbolize_keys: true)

            case response
            when Net::HTTPSuccess
              ServiceResult.success(result: json)
            when Net::HTTPNotFound
              ServiceResult.failure(result: :not_found,
                                    errors: ::Storages::StorageError.new(code: :not_found, data: json))
            when Net::HTTPForbidden
              ServiceResult.failure(result: :forbidden,
                                    errors: ::Storages::StorageError.new(code: :forbidden, data: json))
            when Net::HTTPUnauthorized
              ServiceResult.failure(result: :unauthorized,
                                    errors: ::Storages::StorageError.new(code: :unauthorized, data: json))
            else
              ServiceResult.failure(result: :error,
                                    errors: ::Storages::StorageError.new(code: :error, data: json))
            end
          end
        end
      end
    end
  end
end

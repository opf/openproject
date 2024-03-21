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

module Storages::Peripherals::StorageInteraction::Nextcloud
  class UploadLinkQuery
    using Storages::Peripherals::ServiceResultRefinements

    URI_TOKEN_REQUEST = "index.php/apps/integration_openproject/direct-upload-token"
    URI_UPLOAD_BASE_PATH = "index.php/apps/integration_openproject/direct-upload"

    def initialize(storage)
      @uri = storage.uri
      @configuration = storage.oauth_configuration
    end

    def self.call(storage:, user:, data:)
      new(storage).call(user:, data:)
    end

    def call(user:, data:)
      Util.token(user:, configuration: @configuration) do |token|
        if data.nil? || data["parent"].nil?
          Util.error(:error, "Data is invalid", data)
        else
          outbound_response(
            relative_path: URI_TOKEN_REQUEST,
            payload: { folder_id: data["parent"] },
            token:
          ).map do |response|
            Storages::UploadLink.new(
              URI.parse(Util.join_uri_path(@uri, URI_UPLOAD_BASE_PATH, response.token))
            )
          end
        end
      end
    end

    private

    def outbound_response(relative_path:, payload:, token:)
      response = OpenProject
                   .httpx
                   .with(headers: { "Authorization" => "Bearer #{token.access_token}",
                                    "Accept" => "application/json",
                                    "Content-Type" => "application/json" })
                   .post(
                     Util.join_uri_path(@uri, relative_path),
                     json: payload
                   )
      case response
      in { status: 200..299 }
        # The nextcloud API returns a successful response with empty body if the authorization is missing or expired
        if response.body.present?
          ServiceResult.success(
            result: JSON.parse(response.body.to_s, object_class: OpenStruct) # rubocop:disable Style/OpenStructUse
          )
        else
          Util.error(:unauthorized, "Outbound request not authorized!")
        end
      in { status: 404 }
        Util.error(:not_found, "Outbound request destination not found!", response)
      in { status: 401 }
        Util.error(:unauthorized, "Outbound request not authorized!", response)
      else
        Util.error(:error, "Outbound request failed!")
      end
    end
  end
end

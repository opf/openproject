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

module Storages::Peripherals::StorageInteraction::Nextcloud
  class UploadLinkQuery
    using Storages::Peripherals::ServiceResultRefinements

    URI_TOKEN_REQUEST = 'index.php/apps/integration_openproject/direct-upload-token'.freeze
    URI_UPLOAD_BASE_PATH = 'index.php/apps/integration_openproject/direct-upload'.freeze

    def initialize(storage)
      @base_uri = URI(storage.host).normalize
      @oauth_client = storage.oauth_client
    end

    def call(user:, data:)
      Util.token(user:, oauth_client: @oauth_client) do |token|
        if data.nil? || data['parent'].nil?
          Util.error(:error, 'Data is invalid', data)
        else
          outbound_response(
            method: :post,
            relative_path: URI_TOKEN_REQUEST,
            payload: { folder_id: data['parent'] },
            token:
          ).map do |response|
            Storages::UploadLink.new(
              URI.parse(Util.join_uri_path(@base_uri, URI_UPLOAD_BASE_PATH, response.token))
            )
          end
        end
      end
    end

    private

    # rubocop:disable Metrics/AbcSize
    def outbound_response(method:, relative_path:, payload:, token:)
      response = begin
        ServiceResult.success(
          result: RestClient::Request.execute(
            method:,
            url: Util.join_uri_path(@base_uri, relative_path),
            payload: payload.to_json,
            headers: {
              'Authorization' => "Bearer #{token.access_token}",
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
        )
      rescue RestClient::Unauthorized => e
        Util.error(:not_authorized, 'Outbound request not authorized!', e.response)
      rescue RestClient::NotFound => e
        Util.error(:not_found, 'Outbound request destination not found!', e.response)
      rescue RestClient::ExceptionWithResponse => e
        Util.error(:error, 'Outbound request failed!', e.response)
      rescue StandardError
        Util.error(:error, 'Outbound request failed!')
      end

      # rubocop:disable Style/OpenStructUse
      # rubocop:disable Style/MultilineBlockChain
      response
        .bind do |r|
        # The nextcloud API returns a successful response with empty body if the authorization is missing or expired
        if r.body.blank?
          Util.error(:not_authorized, 'Outbound request not authorized!')
        else
          ServiceResult.success(result: r)
        end
      end.map { |r| JSON.parse(r.body, object_class: OpenStruct) }
      # rubocop:enable Style/MultilineBlockChain
      # rubocop:enable Style/OpenStructUse Style/MultilineBlockChain
    end

    # rubocop:enable Metrics/AbcSize
  end
end

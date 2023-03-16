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
  class UploadLinkQuery < Storages::Peripherals::StorageInteraction::StorageQuery
    using Storages::Peripherals::ServiceResultRefinements # use '>>' (bind) operator for ServiceResult

    URI_TOKEN_REQUEST = 'apps/integration_openproject/direct-upload-token'.freeze
    URI_UPLOAD_BASE_PATH = 'apps/integration_openproject/direct-upload'.freeze

    def initialize(base_uri:, token:, retry_proc:)
      super()

      @base_uri = base_uri
      @token = token
      @retry_proc = retry_proc
    end

    def query(data)
      validated(data) >>
        method(:request_direct_upload_token) >>
        method(:build_upload_link)
    end

    private

    def validated(data)
      if data.nil? || data['parent'].nil?
        error(:error, 'Data is invalid', data)
      else
        ServiceResult.success(
          result: Struct.new(:parent).new(data['parent'])
        )
      end
    end

    def request_direct_upload_token(data)
      outbound_response(
        method: :post,
        relative_path: URI_TOKEN_REQUEST,
        payload: { folder_id: data.parent }
      )
    end

    def build_upload_link(response)
      destination = URI.parse(File.join(@base_uri.to_s, URI_UPLOAD_BASE_PATH, response.token))
      ServiceResult.success(result: Storages::UploadLink.new(destination))
    end

    # rubocop:disable Metrics/AbcSize
    def outbound_response(method:, relative_path:, payload:)
      @retry_proc.call(@token) do |token|
        begin
          response = ServiceResult.success(
            result: RestClient::Request.execute(
              method:,
              url: File.join(@base_uri.to_s, relative_path),
              payload: payload.to_json,
              headers: {
                'Authorization' => "Bearer #{token.access_token}",
                'Accept' => 'application/json',
                'Content-Type' => 'application/json'
              }
            )
          )
        rescue RestClient::Unauthorized => e
          response = error(:not_authorized, 'Outbound request not authorized!', e.response)
        rescue RestClient::NotFound => e
          response = error(:not_found, 'Outbound request destination not found!', e.response)
        rescue RestClient::ExceptionWithResponse => e
          response = error(:error, 'Outbound request failed!', e.response)
        rescue StandardError
          response = error(:error, 'Outbound request failed!')
        end

        # rubocop:disable Style/OpenStructUse
        # rubocop:disable Style/MultilineBlockChain
        response
          .bind do |r|
          # The nextcloud API returns a successful response with empty body if the authorization is missing or expired
          if r.body.blank?
            error(:not_authorized, 'Outbound request not authorized!')
          else
            ServiceResult.success(result: r)
          end
        end
          .map { |r| JSON.parse(r.body, object_class: OpenStruct) }
        # rubocop:enable Style/MultilineBlockChain
        # rubocop:enable Style/OpenStructUse Style/MultilineBlockChain
      end
    end
    # rubocop:enable Metrics/AbcSize

    def error(code, log_message = nil, data = nil)
      ServiceResult.failure(
        result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
        errors: Storages::StorageError.new(code:, log_message:, data:)
      )
    end
  end
end

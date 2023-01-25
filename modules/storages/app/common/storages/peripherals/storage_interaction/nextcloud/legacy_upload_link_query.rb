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
  class LegacyUploadLinkQuery < Storages::Peripherals::StorageInteraction::StorageQuery
    using Storages::Peripherals::ServiceResultRefinements # use '>>' (bind) operator for ServiceResult

    URI_BASE_PATH = '/ocs/v2.php/apps/files_sharing/api/v1/shares'.freeze
    UPLOAD_LINK_BASE = '/public.php/webdav'.freeze

    def initialize(base_uri:, token:, retry_proc:)
      super()

      @base_uri = base_uri
      @token = token
      @retry_proc = retry_proc
    end

    def query(data)
      validated(data) >>
        method(:create_file_share) >>
        method(:apply_drop_permission) >>
        method(:build_upload_link)
    end

    private

    def validated(data)
      if data.nil? || data['fileName'].nil? || data['parent'].nil?
        error(:error, 'Data is invalid', data)
      else
        ServiceResult.success(
          result: Struct.new(:file_name, :parent)
                        .new(data['fileName'], data['parent'])
        )
      end
    end

    def create_file_share(data)
      password = SecureRandom.uuid

      outbound_response(
        method: :post,
        relative_path: URI_BASE_PATH,
        payload: {
          shareType: 3,
          password:,
          path: data.parent,
          expireDate: Date.tomorrow
        }
      ).map do |response|
        Struct.new(:id, :token, :password, :file_name)
              .new(response.ocs.data.id, response.ocs.data.token, password, data.file_name)
      end
    end

    def apply_drop_permission(share)
      outbound_response(
        method: :put,
        relative_path: "#{URI_BASE_PATH}/#{share.id}",
        payload: {
          permissions: 5
        }
      ).map { share }
    end

    def build_upload_link(share)
      destination = @base_uri.merge("#{UPLOAD_LINK_BASE}/#{ERB::Util.url_encode(share.file_name)}")
      destination.user = share.token
      destination.password = share.password

      ServiceResult.success(result: Storages::UploadLink.new(destination, :put))
    end

    def outbound_response(method:, relative_path:, payload:) # rubocop:disable Metrics/AbcSize
      @retry_proc.call(@token) do |token|
        begin
          response = ServiceResult.success(
            result: RestClient::Request.execute(
              method:,
              url: @base_uri.merge(relative_path).to_s,
              payload: payload.to_json,
              headers: {
                'Authorization' => "Bearer #{token.access_token}",
                'OCS-APIRequest' => 'true',
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

    def error(code, log_message = nil, data = nil)
      ServiceResult.failure(
        result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
        errors: Storages::StorageError.new(code:, log_message:, data:)
      )
    end
  end
end

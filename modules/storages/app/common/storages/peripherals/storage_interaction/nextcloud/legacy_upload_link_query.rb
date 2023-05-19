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
  class LegacyUploadLinkQuery
    using Storages::Peripherals::ServiceResultRefinements

    URI_BASE_PATH = '/ocs/v2.php/apps/files_sharing/api/v1/shares'.freeze
    UPLOAD_LINK_BASE = '/public.php/webdav'.freeze

    def initialize(storage)
      @uri = URI(storage.host).normalize
      @oauth_client = storage.oauth_client
    end

    def call(user:, data:)
      @user = user
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
      destination = @uri.merge("#{UPLOAD_LINK_BASE}/#{CGI.escapeURIComponent(share.file_name)}")
      destination.user = share.token
      destination.password = share.password

      ServiceResult.success(result: Storages::UploadLink.new(destination, :put))
    end

    def outbound_response(method:, relative_path:, payload:) # rubocop:disable Metrics/AbcSize
      response = Util.token(user: @user, oauth_client: @oauth_client) do |token|
        response = begin
          ServiceResult.success(
            result: RestClient::Request.execute(
              method:,
              url: @uri.merge(relative_path).to_s,
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
          end
          .map { |r| JSON.parse(r.body, object_class: OpenStruct) }
        # rubocop:enable Style/MultilineBlockChain
        # rubocop:enable Style/OpenStructUse Style/MultilineBlockChain
      end
    end
  end
end

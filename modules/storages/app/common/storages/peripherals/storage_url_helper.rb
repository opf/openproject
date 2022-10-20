#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module Storages::Peripherals
  # Helper for open and download links for a file link object.
  module StorageUrlHelper
    def storage_url_open_file(file_link, open_location: false)
      location_flag = ActiveModel::Type::Boolean.new.cast(open_location) ? 0 : 1

      "#{file_link.storage.host}/index.php/f/#{file_link.origin_id}?openfile=#{location_flag}"
    end

    def storage_url_open(storage)
      "#{storage.host}/index.php/apps/files"
    end

    # rubocop:disable Metrics/AbcSize
    def make_download_url(file_link:, user:)
      storage = file_link.storage
      oauth_client = storage.oauth_client

      client_token = get_oauth_client_token(user:, oauth_client:)
      return client_token if client_token.failure?

      direct_download_response = make_direct_download storage:,
                                                      access_token: client_token.result.access_token,
                                                      file_id: file_link.origin_id

      return direct_download_response if direct_download_response.failure?

      download_token = direct_download_token(body: direct_download_response.result)
      return download_token if download_token.failure?

      url = "#{storage.host}/index.php/apps/integration_openproject/direct/#{download_token.result}/#{file_link.origin_name}"
      ServiceResult.success(result: url)
    end

    # rubocop:enable Metrics/AbcSize

    private

    def get_oauth_client_token(user:, oauth_client:)
      client_token = ::OAuthClients::ConnectionManager
                       .new(user:, oauth_client:)
                       .get_access_token

      client_token.success? ? client_token : ServiceResult.failure(result: I18n.t('http.request.missing_authorization'))
    end

    def make_direct_download(storage:, access_token:, file_id:)
      response = Storages::Peripherals::StorageRequests
                   .new(storage:)
                   .download_command
                   .call(access_token:, file_id:)

      return response if response.failure?

      # The nextcloud API returns a successful response with empty body if the authorization is missing or expired
      return ServiceResult.failure(result: I18n.t('http.request.failed_authorization')) if response.result.body.blank?

      ServiceResult.success(result: response.result.body)
    end

    def direct_download_token(body:)
      token = parse_direct_download_token(body:)
      if token.blank?
        Rails.logger.error "Received unexpected json response: #{body}"
        return ServiceResult.failure(result: I18n.t('http.response.unexpected'))
      end

      ServiceResult.success(result: token)
    end

    def parse_direct_download_token(body:)
      begin
        json = JSON.parse body
      rescue JSON::ParserError
        return nil
      end

      direct_download_url = json.dig('ocs', 'data', 'url')
      return nil if direct_download_url.blank?

      path = URI.parse(direct_download_url).path
      return nil if path.blank?

      path.split('/').last
    end
  end
end

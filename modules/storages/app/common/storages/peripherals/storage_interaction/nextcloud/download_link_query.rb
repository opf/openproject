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
  class DownloadLinkQuery
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @uri = storage.uri
      @configuration = storage.oauth_configuration
    end

    def self.call(storage:, user:, file_link:)
      new(storage).call(user:, file_link:)
    end

    def call(user:, file_link:)
      result = Util.token(user:, configuration: @configuration) do |token|
        direct_download_request(token, file_link).bind do |resp|
          # The nextcloud API returns a successful response with empty body if the authorization is missing or expired
          if resp.body.blank?
            Util.error(:unauthorized, "Outbound request not authorized!")
          else
            ServiceResult.success(result: resp.body.to_s)
          end
        end
      end

      result
        .bind { |response_body| direct_download_token(body: response_body) }
        .map { |download_token| download_link(download_token, file_link.origin_name) }
    end

    private

    def direct_download_request(token, file_link)
      response = OpenProject
                   .httpx
                   .post(
                     Util.join_uri_path(@uri, "/ocs/v2.php/apps/dav/api/v1/direct"),
                     json: { fileId: file_link.origin_id },
                     headers: {
                       "Authorization" => "Bearer #{token.access_token}",
                       "OCS-APIRequest" => "true",
                       "Accept" => "application/json",
                       "Content-Type" => "application/json"
                     }
                   )
      case response
      in { status: 200..299 }
        ServiceResult.success(result: response)
      in { status: 404 }
        Util.error(:not_found, "Outbound request destination not found!", response)
      in { status: 401 }
        Util.error(:unauthorized, "Outbound request not authorized!", response)
      else
        Util.error(:error, "Outbound request failed!")
      end
    end

    def download_link(token, origin_name)
      Util.join_uri_path(@uri, "index.php/apps/integration_openproject/direct", token, CGI.escape(origin_name))
    end

    def direct_download_token(body:)
      token = parse_direct_download_token(body:)
      if token.blank?
        return Util.error(:error, "Received unexpected json response", body)
      end

      ServiceResult.success(result: token)
    end

    def parse_direct_download_token(body:)
      begin
        json = JSON.parse(body)
      rescue JSON::ParserError
        return nil
      end

      direct_download_url = json.dig("ocs", "data", "url")
      return nil if direct_download_url.blank?

      path = URI.parse(direct_download_url).path
      return nil if path.blank?

      path.split("/").last
    end
  end
end

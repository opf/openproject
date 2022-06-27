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

module API
  module V3
    module FileLinks
      class FileLinksDownloadAPI < ::API::OpenProjectAPI
        helpers do
          def parse_response_body(body)
            begin
              json = JSON.parse body
            rescue JSON::ParserError
              return nil
            end

            json.dig('ocs', 'data', 'url')
          end
        end

        resources :download do
          get do
            oauth_client_information = @file_link.storage.oauth_client

            token_result = ::OAuthClients::ConnectionManager
                             .new(user: User.current, oauth_client: oauth_client_information)
                             .get_access_token

            raise API::Errors::InternalError.new(I18n.t('http.request.missing_authorization')) if token_result.failure?

            response = API::V3::Storages::StorageRequestFactory
                         .new(oauth_client: oauth_client_information)
                         .download_command
                         .call(
                           access_token: token_result.result.access_token,
                           file_id: @file_link.origin_id
                         )

            raise API::Errors::InternalError.new(response.result) if response.failure?
            # The nextcloud API returns a successful response with empty body if the authorization is missing or expired
            raise API::Errors::InternalError.new(I18n.t('http.request.failed_authorization')) if response.result.body.blank?

            download_url = parse_response_body response.result.body
            # download_url = 'https://nextcloud.ripley.minifox.fr/remote.php/direct/s3EbjrmfAS4wFTmPhksdbMN2ZwBv3Ehu2drrUbUvBryLdZQAr1eCwjMlaLdJ'

            if download_url.blank?
              Rails.logger.error "Received unexpected json response: #{response.result.body}"
              raise API::Errors::InternalError.new(I18n.t('http.response.unexpected'))
            end

            redirect download_url, body: "The requested resource can be downloaded from #{download_url}"
            status 303
          end
        end
      end
    end
  end
end

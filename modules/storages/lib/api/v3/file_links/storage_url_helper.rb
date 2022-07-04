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

# Helper for open and download links for a file link object.
module API::V3::FileLinks::StorageUrlHelper
  include Dry::Monads[:result, :do, :try]

  def storage_url_open(file_link, open_location: false)
    location_flag = ActiveModel::Type::Boolean.new.cast(open_location) ? 0 : 1

    "#{file_link.storage.host}/f/#{file_link.origin_id}?openfile=#{location_flag}"
  end

  def make_download_url(file_link:, user:)
    storage = file_link.storage
    oauth_client = storage.oauth_client

    client_token = yield ::OAuthClients::ConnectionManager
                           .new(user:, oauth_client:)
                           .get_access_token_monad

    response = yield make_direct_download oauth_client:,
                                          access_token: client_token.access_token,
                                          file_id: file_link.origin_id

    token = yield parse_direct_download_token(body: response).to_result(I18n.t('http.response.unexpected'))

    Success("#{storage.host}/apps/integration_openproject/direct/#{token}/#{file_link.origin_name}")
  end

  private

  def make_direct_download(oauth_client:, access_token:, file_id:)
    result = yield API::V3::Storages::StorageRequestFactory
                     .new(oauth_client:)
                     .download_command
                     .call(access_token:, file_id:)

    # The nextcloud API returns a successful response with empty body if the authorization is missing or expired.
    result.body.present? ? Success(result) : Failure(I18n.t('http.request.failed_authorization'))
  end

  def parse_direct_download_token(body:)
    json = yield Try[JSON::ParserError] { JSON.parse body }.to_maybe
    url = yield Maybe json.dig('ocs', 'data', 'url')
    path = yield Maybe URI.parse(url).path

    Maybe path.split('/').last
  end
end

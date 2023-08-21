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

module Storages::Peripherals::StorageInteraction::Nextcloud::Util
  using Storages::Peripherals::ServiceResultRefinements

  class << self
    def escape_path(path)
      path.split('/').map { |i| CGI.escapeURIComponent(i) }.join('/')
    end

    def basic_auth_header(username, password)
      {
        'Authorization' => "Basic #{Base64::strict_encode64("#{username}:#{password}")}"
      }
    end

    def error(code, log_message = nil, data = nil)
      ServiceResult.failure(
        result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
        errors: Storages::StorageError.new(code:, log_message:, data:)
      )
    end

    def join_uri_path(uri, *parts)
      # We use `File.join` to ensure single `/` in between every part. This API will break if executed on a
      # Windows context, as it used `\` as file separators. But we anticipate that OpenProject
      # Server is not run on a Windows context.
      # URI::join cannot be used, as it behaves very different for the path parts depending on trailing slashes.
      File.join(uri.to_s, *parts)
    end

    def token(user:, oauth_client:, &block)
      connection_manager = ::OAuthClients::ConnectionManager.new(user:, oauth_client:)
      connection_manager.get_access_token.match(
        on_success: ->(token) do
          connection_manager.request_with_token_refresh(token) { block.call(token) }
        end,
        on_failure: ->(_) { error(:not_authorized, 'Query could not be created! No access token found!') }
      )
    end

    def http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http
    end

    def error_text_from_response(response)
      Nokogiri::XML(response.body).xpath("//s:message").text
    end
  end
end

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

module Storages::Peripherals::StorageInteraction::Nextcloud::Util
  using Storages::Peripherals::ServiceResultRefinements

  class << self
    def escape_path(path)
      escaped_path = path.split('/').map { |i| CGI.escapeURIComponent(i) }.join('/')
      escaped_path << '/' if path[-1] == '/'
      escaped_path
    end

    def ocs_api_request
      { headers: { 'OCS-APIRequest' => 'true' } }
    end

    def error(code, log_message = nil, data = nil)
      ServiceResult.failure(
        result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
        errors: Storages::StorageError.new(code:, log_message:, data:)
      )
    end

    def join_uri_path(uri, *)
      # We use `File.join` to ensure single `/` in between every part. This API will break if executed on a
      # Windows context, as it used `\` as file separators. But we anticipate that OpenProject
      # Server is not run on a Windows context.
      # URI::join cannot be used, as it behaves very different for the path parts depending on trailing slashes.
      File.join(uri.to_s, *)
    end

    def token(user:, configuration:, &)
      connection_manager = ::OAuthClients::ConnectionManager.new(user:, configuration:)
      connection_manager.get_access_token.match(
        on_success: ->(token) do
          connection_manager.request_with_token_refresh(token) { yield token }
        end,
        on_failure: ->(_) do
          error(:unauthorized,
                'Query could not be created! No access token found!',
                Storages::StorageErrorData.new(source: connection_manager))
        end
      )
    end

    def error_text_from_response(response)
      Nokogiri::XML(response.body).xpath("//s:message").text
    end
  end
end

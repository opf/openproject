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

module Storages::Peripherals::StorageInteraction
  class StorageQueries
    using ::Storages::Peripherals::ServiceResultRefinements

    def initialize(uri:, provider_type:, user:, oauth_client:)
      @uri = uri
      @provider_type = provider_type
      @user = user
      @oauth_client = oauth_client
    end

    def download_link_query
      case @provider_type
      when ::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD
        connection_manager = ::OAuthClients::ConnectionManager.new(user: @user, oauth_client: @oauth_client)
        connection_manager.get_access_token.match(
          on_success: ->(token) do
            ServiceResult.success(
              result:
                ::Storages::Peripherals::StorageInteraction::Nextcloud::DownloadLinkQuery.new(
                  base_uri: @uri,
                  token:,
                  with_refreshed_token: connection_manager.method(:request_with_token_refresh).to_proc
                )
            )
          end,
          on_failure: ->(_) do
            ServiceResult.failure(result: :not_authorized)
          end
        )
      else
        raise ArgumentError
      end
    end

    def files_query
      case @provider_type
      when ::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD
        connection_manager = ::OAuthClients::ConnectionManager.new(user: @user, oauth_client: @oauth_client)
        connection_manager.get_access_token.match(
          on_success: ->(token) do
            ServiceResult.success(
              result:
                ::Storages::Peripherals::StorageInteraction::Nextcloud::FilesQuery.new(
                  base_uri: @uri,
                  token:,
                  with_refreshed_token: connection_manager.method(:request_with_token_refresh).to_proc
                )
            )
          end,
          on_failure: ->(_) do
            ServiceResult.failure(result: :not_authorized)
          end
        )
      else
        raise ArgumentError
      end
    end
  end
end

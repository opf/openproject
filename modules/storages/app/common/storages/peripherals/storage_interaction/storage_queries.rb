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
        retry_with_refreshed_token do |token, with_refreshed_token_proc|
          ::Storages::Peripherals::StorageInteraction::Nextcloud::DownloadLinkQuery.new(
            base_uri: @uri,
            token:,
            retry_proc: with_refreshed_token_proc
          )
        end
      else
        raise ArgumentError
      end
    end

    def upload_link_query
      case @provider_type
      when ::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD
        retry_with_refreshed_token do |token, with_refreshed_token_proc|
          if OpenProject::FeatureDecisions.legacy_upload_preparation_active?
            ::Storages::Peripherals::StorageInteraction::Nextcloud::LegacyUploadLinkQuery.new(
              base_uri: @uri,
              token:,
              retry_proc: with_refreshed_token_proc
            )
          else
            ::Storages::Peripherals::StorageInteraction::Nextcloud::UploadLinkQuery.new(
              base_uri: @uri,
              token:,
              retry_proc: with_refreshed_token_proc
            )
          end
        end
      else
        raise ArgumentError
      end
    end

    def files_query
      case @provider_type
      when ::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD
        retry_with_refreshed_token do |token, with_refreshed_token_proc|
          ::Storages::Peripherals::StorageInteraction::Nextcloud::FilesQuery.new(
            base_uri: @uri,
            token:,
            retry_proc: with_refreshed_token_proc
          )
        end
      else
        raise ArgumentError
      end
    end

    private

    def retry_with_refreshed_token
      connection_manager = ::OAuthClients::ConnectionManager.new(user: @user, oauth_client: @oauth_client)
      connection_manager.get_access_token.match(
        on_success: ->(token) do
          ServiceResult.success(result: yield(token, connection_manager.method(:request_with_token_refresh).to_proc))
        end,
        on_failure: ->(_) { error(:not_authorized, 'Query could not be created! No access token found!') }
      )
    end

    def error(code, log_message = nil, data = nil)
      ServiceResult.failure(errors: Storages::StorageError.new(code:, log_message:, data:))
    end
  end
end

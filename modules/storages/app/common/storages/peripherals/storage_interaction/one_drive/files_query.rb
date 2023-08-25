# frozen_string_literal: true

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

module Storages
  module Peripherals
    module StorageInteraction
      module OneDrive
        class FilesQuery
          using ServiceResultRefinements
          def self.call(storage:, user:, folder:)
            new(storage).call(user:, folder:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(user:, folder:)
            # result = Util.token(user:, oauth_client: @oauth_client) do |token|
            #   base_path = Util.join_uri_path(@uri.path, "remote.php/dav/files")
            #   @location_prefix = Util.join_uri_path(base_path, token.origin_user_id.gsub(' ', '%20'))
            #
            #   response = Util.http(@uri).propfind(
            #     Util.join_uri_path(base_path, CGI.escapeURIComponent(token.origin_user_id), requested_folder(folder)),
            #     requested_properties,
            #     {
            #       'Depth' => '1',
            #       'Authorization' => "Bearer #{token.access_token}"
            #     }
            #   )
            #
            #   case response
            #   when Net::HTTPSuccess
            #     ServiceResult.success(result: response.body)
            #   when Net::HTTPNotFound
            #     Util.error(:not_found)
            #   when Net::HTTPUnauthorized
            #     Util.error(:not_authorized)
            #   else
            #     Util.error(:error)
            #   end
            # end
            #
            # storage_files(result)
            uri = URI('https://graph.microsoft.com').normalize

            using_user_token(user) do |token|
              # Make the Get Request to the necessary endpoints
              request = Net::HTTP.new(uri.host, uri.port)
              request.use_ssl = true
              p request.get(
                '/drives/root/items/children',
                {
                  'Authorization' => "Bearer #{token.access_token}"
                }
              )
              # grab the response
              # parse!
              # Do stuff!
            end

            # Using a token
            # Call the folder_path
            # grab the response
            # parse into Storages::Files
          end

          private

          def using_user_token(user, &block)
            connection_manager = ::OAuthClients::OneDriveConnectionManager
              .new(user:, oauth_client: @storage.oauth_client, tenant_id: @storage.provider_fields['tenant_id'])

            connection_manager
              .get_access_token
              .match(
                on_success: ->(token) do
                  connection_manager.request_with_token_refresh(token) { block.call(token) }
                end,
                on_failure: ->(_) { error(:not_authorized, 'Query could not be created! No access token found!') }
              )
          end
        end
      end
    end
  end
end

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

module Storages
  module Peripherals
    module StorageInteraction
      module OneDrive
        class DownloadLinkQuery
          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def self.call(storage:, user:, file_link:)
            new(storage).call(user:, file_link:)
          end

          def call(user:, file_link:)
            Util.using_user_token(@storage, user) do |token|
              response = OpenProject.httpx.get(
                Util.join_uri_path(
                  @uri,
                  uri_path_for(file_link.origin_id)
                ),
                headers: { "Authorization" => "Bearer #{token.access_token}" }
              )

              handle_errors(response)
            end
          end

          private

          def handle_errors(response)
            case response
            in { status: 300..399 }
              ServiceResult.success(result: response.headers["Location"])
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: ::Storages::StorageError.new(code: :not_found, data: response))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden,
                                    errors: ::Storages::StorageError.new(code: :forbidden, data: response))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: ::Storages::StorageError.new(code: :unauthorized, data: response))
            else
              ServiceResult.failure(result: :error,
                                    errors: ::Storages::StorageError.new(code: :error, data: response))
            end
          end

          def uri_path_for(file_id)
            "/v1.0/drives/#{@storage.drive_id}/items/#{file_id}/content"
          end
        end
      end
    end
  end
end

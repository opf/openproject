# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
      module Nextcloud
        class RenameFileCommand
          include TaggedLogging

          def self.call(storage:, auth_strategy:, file_id:, name:)
            new(storage).call(auth_strategy:, file_id:, name:)
          end

          def initialize(storage)
            @storage = storage
          end

          # rubocop:disable Metrics/AbcSize
          def call(auth_strategy:, file_id:, name:)
            validate_input_data(file_id:, name:).on_failure { |failure| return failure }

            with_tagged_logger do
              info "Validating user remote ID"
              origin_user_id = Util.origin_user_id(caller: self.class, storage: @storage, auth_strategy:)
                                   .on_failure { |failure| return failure }
                                   .result

              info "Getting the folder information"
              info = FileInfoQuery.call(storage: @storage, auth_strategy:, file_id:)
                                  .on_failure { |failure| return failure }
                                  .result

              info "Renaming the folder #{info.location} to #{name}"
              make_request(auth_strategy, origin_user_id, info, name).on_failure { |failure| return failure }

              info "Retrieving updated file info for the #{name} folder"
              FileInfoQuery.call(storage: @storage, auth_strategy:, file_id:)
                           .map { |file_info| Util.storage_file_from_file_info(file_info) }
            end
          end
          # rubocop:enable Metrics/AbcSize

          private

          def make_request(auth_strategy, user, file_info, name)
            source_path = UrlBuilder.url(@storage.uri,
                                         "remote.php/dav/files",
                                         user,
                                         CGI.unescape(file_info.location))

            destination = UrlBuilder.path(@storage.uri.path,
                                          "remote.php/dav/files",
                                          user,
                                          CGI.unescape(target_path(file_info, name)))

            Authentication[auth_strategy].call(storage: @storage) do |http|
              handle_response http.request("MOVE", source_path, headers: { "Destination" => destination })
            end
          end

          def target_path(info, name)
            info.location.gsub(CGI.escapeURIComponent(info.name), CGI.escapeURIComponent(name))
          end

          def validate_input_data(file_id:, name:)
            if file_id.blank? || name.blank?
              ServiceResult.failure(result: :error,
                                    errors: StorageError.new(code: :error,
                                                             data: StorageErrorData.new(source: self.class),
                                                             log_message: "file_id or name is blank"))
            else
              ServiceResult.success
            end
          end

          def handle_response(response)
            error_data = StorageErrorData.new(source: self.class, payload: response)
            case response
            in { status: 200..299 }
              ServiceResult.success
            in { status: 404 }
              Util.error(:not_found, "Outbound request destination not found", error_data)
            in { status: 401 }
              Util.error(:unauthorized, "Outbound request not authorized", error_data)
            else
              Util.error(:error, "Outbound request failed", error_data)
            end
          end
        end
      end
    end
  end
end

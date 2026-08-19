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
  module Adapters
    module Providers
      module Nextcloud
        module Commands
          class RenameFileCommand < Base
            def initialize(*)
              super
              @file_info_query = Queries::FileInfoQuery.new(@storage)
            end

            # rubocop:disable Metrics/AbcSize
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                info "Validating user remote ID"
                origin_user_id(auth_strategy:).bind do |origin_user_id|
                  info "Getting the folder information"
                  Input::FileInfo.build(file_id: input_data.location.path).bind do |info_input_data|
                    @file_info_query.call(auth_strategy:, input_data: info_input_data).bind do |fileinfo|
                      info "Renaming the folder #{fileinfo.location} to #{input_data.new_name}"
                      make_request(auth_strategy, origin_user_id, fileinfo, input_data.new_name).bind do
                        info "Retrieving updated file info for the #{input_data.new_name} folder"
                        @file_info_query.call(auth_strategy:, input_data: info_input_data).bind(&:to_storage_file)
                      end
                    end
                  end
                end
              end
            end
            # rubocop:enable Metrics/AbcSize

            private

            def make_request(auth_strategy, user, file_info, name)
              source_path = UrlBuilder.url(@storage.uri,
                                           "remote.php/dav/files",
                                           user,
                                           file_info.location)

              destination = UrlBuilder.path(@storage.uri.path,
                                            "remote.php/dav/files",
                                            user,
                                            target_path(file_info, name))

              Authentication[auth_strategy].call(storage: @storage) do |http|
                handle_response http.request("MOVE", source_path, headers: { "Destination" => destination, "Overwrite" => "F" })
              end
            end

            def target_path(info, name)
              info.location.gsub(info.name, name)
            end

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)
              case response
              in { status: 200..299 }
                Success()
              in { status: 412 }
                Failure(error.with(code: :conflict))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error.with(code: :error))
              end
            end
          end
        end
      end
    end
  end
end

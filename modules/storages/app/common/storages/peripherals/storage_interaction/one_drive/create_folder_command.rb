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
      module OneDrive
        class CreateFolderCommand
          include TaggedLogging
          using ServiceResultRefinements

          def self.call(storage:, auth_strategy:, folder_name:, parent_location:)
            new(storage).call(auth_strategy:, folder_name:, parent_location:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, folder_name:, parent_location:)
            with_tagged_logger do
              info "Creating folder #{folder_name} under #{parent_location} using #{auth_strategy.key}"
              Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
                handle_response http.post(url_for(parent_location), body: payload(folder_name))
              end
            end
          end

          private

          def http_options
            Util.json_content_type
          end

          def url_for(parent_location)
            if parent_location.root?
              UrlBuilder.url(Util.drive_base_uri(@storage), "/root/children")
            else
              UrlBuilder.url(Util.drive_base_uri(@storage), "/items", parent_location.path, "/children")
            end
          end

          def handle_response(response)
            source = self.class

            case response
            in { status: 200..299 }
              info "Folder successfully created."
              ServiceResult.success(result:
                                      Util.storage_file_from_json(MultiJson.load(response.body, symbolize_keys: true)))
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: Util.storage_error(code: :not_found, response:, source:))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(code: :unauthorized, response:, source:))
            in { status: 409 }
              ServiceResult.failure(result: :already_exists,
                                    errors: Util.storage_error(code: :conflict, response:, source:))
            else
              ServiceResult.failure(result: :error,
                                    errors: Util.storage_error(code: :error, response:, source:))
            end
          end

          def payload(folder_name)
            {
              name: folder_name,
              folder: {},
              "@microsoft.graph.conflictBehavior" => "fail"
            }.to_json
          end
        end
      end
    end
  end
end

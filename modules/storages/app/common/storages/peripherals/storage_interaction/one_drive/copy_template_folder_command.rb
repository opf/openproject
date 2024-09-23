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
        class CopyTemplateFolderCommand
          include TaggedLogging

          def self.call(auth_strategy:, storage:, source_path:, destination_path:)
            if source_path.blank? || destination_path.blank?
              return ServiceResult.failure(
                result: :error,
                errors: StorageError.new(code: :error,
                                         log_message: "Both source and destination paths need to be present")
              )
            end

            new(storage).call(auth_strategy:, source_location: source_path, destination_name: destination_path)
          end

          def initialize(storage)
            @storage = storage
            @data = ResultData::CopyTemplateFolder.new(id: nil, polling_url: nil, requires_polling: true)
          end

          def call(auth_strategy:, source_location:, destination_name:)
            with_tagged_logger do
              info "Requesting Copy of folder #{source_location} to #{destination_name}"
              Authentication[auth_strategy].call(storage: @storage) do |httpx|
                handle_response(
                  httpx.post(url_for(source_location) + query, json: { name: destination_name })
                )
              end
            end
          end

          private

          def handle_response(response)
            source = self.class

            case response
            in { status: 202 }
              ServiceResult.success(result: @data.with(polling_url: response.headers[:location]))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(response:, code: :unauthorized, source:))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden,
                                    errors: Util.storage_error(response:, code: :forbidden, source:))
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: Util.storage_error(response:, code: :not_found, source:,
                                                               log_message: "Template folder not found"))
            in { status: 409 }
              ServiceResult.failure(result: :conflict,
                                    errors: Util.storage_error(
                                      response:, code: :conflict, source:,
                                      log_message: "The copy would overwrite an already existing folder"
                                    ))
            else
              ServiceResult.failure(result: :error,
                                    errors: Util.storage_error(response:, code: :error, source:))
            end
          end

          def url_for(source_location)
            UrlBuilder.url(Util.drive_base_uri(@storage), "/items", source_location, "/copy")
          end

          def query = "?@microsoft.graph.conflictBehavior=fail"
        end
      end
    end
  end
end

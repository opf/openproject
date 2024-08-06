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
        class CapabilitiesQuery
          include Dry::Monads[:result]
          include Dry::Monads::Do.for(:call, :parse_capabilities)

          def self.call(storage:, auth_strategy:)
            new(storage).call(auth_strategy:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:)
            http_options = Util.ocs_api_request.deep_merge(Util.accept_json)
            result = Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
              json = yield handle_response(http.get(url))

              parse_capabilities(json)
            end

            to_service_result(result)
          end

          private

          def url = UrlBuilder.url(@storage.uri, "/ocs/v2.php/cloud/capabilities")

          def handle_response(response)
            error_data = StorageErrorData.new(source: self.class, payload: response.to_s)

            case response
            in { status: 200..299 }
              Success(response.json(symbolize_keys: true))
            in { status: 404 }
              Failure(StorageError.new(code: :not_found,
                                       log_message: "Outbound request destination not found!",
                                       data: error_data))
            else
              Failure(StorageError.new(code: :error,
                                       log_message: "Outbound request failed!",
                                       data: error_data))
            end
          end

          # rubocop:disable Metrics/AbcSize
          def parse_capabilities(json)
            capabilities = NextcloudCapabilities.empty

            app_json = json.dig(:ocs, :data, :capabilities, :integration_openproject)
            capabilities = capabilities.with(app_enabled?: app_json.present?)

            return Success(capabilities) if app_json.nil?

            app_version = yield version(app_json[:app_version])
            group_folder_enabled = !!app_json[:groupfolders_enabled]
            capabilities = capabilities.with(app_version:, group_folder_enabled?: group_folder_enabled)

            return Success(capabilities) unless group_folder_enabled

            group_folder_version = yield version(app_json[:groupfolder_version])
            Success(capabilities.with(group_folder_version:))
          end

          # rubocop:enable Metrics/AbcSize

          def version(str)
            failure = Failure(StorageError.new(code: :error, log_message: "'#{str}' is not a valid version string"))

            return failure if str.nil?

            major, minor, patch = str.split(".").map(&:to_i)

            return failure if major.nil? || minor.nil? || patch.nil?

            Success(SemanticVersion.new(major:, minor:, patch:))
          end

          def to_service_result(result)
            result.either(
              ->(r) { ServiceResult.success(result: r) },
              ->(f) { ServiceResult.failure(result: f.code, errors: f) }
            )
          end
        end
      end
    end
  end
end

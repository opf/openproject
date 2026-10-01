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
        module Queries
          class FileInfoQuery < Base
            FILE_INFO_PATH = "ocs/v1.php/apps/integration_openproject/fileinfo"

            def call(auth_strategy:, input_data:)
              http_options = ocs_api_request_headers.deep_merge(headers: { "Accept" => "application/json" })
              Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
                file_info(http, input_data.file_id).bind do |json|
                  validate_response_object(json).bind do |valid_response|
                    create_storage_file_info(valid_response)
                  end
                end
              end
            end

            private

            def file_info(http, file_id)
              response = http.get(UrlBuilder.url(@storage.uri, FILE_INFO_PATH, file_id))
              error = SimpleError.new(source: self.class, payload: response, code: :error)

              case response
              in { status: 200..299 }
                parse_json(response, error).bind { fail_on_ocs_error(it, error) }
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error)
              end
            end

            def validate_response_object(json)
              error = SimpleError.new(source: self.class, code: :error, payload: json)

              case json_fetch(json, :ocs, :data, :statuscode)
              when 200..299
                Success(json)
              when 403
                Failure(error.with(code: :forbidden))
              when 404
                Failure(error.with(code: :not_found))
              else
                Failure(error)
              end
            end

            def create_storage_file_info(json) # rubocop:disable Metrics/AbcSize
              data = json_fetch(json, :ocs, :data)
              error = SimpleError.new(source: self.class, code: :invalid_file_info)
              Results::StorageFileInfo.build(
                status: data[:status]&.downcase,
                status_code: data[:statuscode],
                id: data[:id]&.to_s,
                name: data[:name],
                last_modified_at: Time.zone.at(data[:mtime]).iso8601,
                created_at: Time.zone.at(data[:ctime]).iso8601,
                mime_type: data[:mimetype],
                size: data[:size],
                owner_name: data[:owner_name],
                owner_id: data[:owner_id],
                last_modified_by_name: data[:modifier_name],
                last_modified_by_id: data[:modifier_id],
                permissions: data[:dav_permissions],
                location: location(data[:path])
              ).or { Failure(error.with(payload: it.errors.messages)) }
            end

            def location(file_path)
              prefix = "files/"
              idx = file_path.index(prefix)
              return "/" if idx == nil

              idx += prefix.length - 1

              file_path[idx..].chomp("/")
            end
          end
        end
      end
    end
  end
end

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

module Storages::Peripherals::StorageInteraction::Nextcloud
  class CopyTemplateFolderCommand
    using Storages::Peripherals::ServiceResultRefinements

    def self.call(storage:, source_path:, destination_path:)
      new(storage).call(source_path:, destination_path:)
    end

    def initialize(storage)
      @storage = storage
    end

    def call(source_path:, destination_path:)
      valid_input_result = validate_inputs(source_path, destination_path).on_failure { |failure| return failure }

      remote_urls = build_origin_urls(**valid_input_result.result)

      remote_folder_does_not_exist?(remote_urls[:destination_url]).on_failure { |failure| return failure }

      copy_folder(**remote_urls).on_failure { |failure| return failure }

      get_folder_id(valid_input_result.result[:destination_path]).on_success do |command_result|
        return ServiceResult
          .success(result: { id: command_result.result[destination_path]['fileid'], url: remote_urls[:destination_url] })
      end
    end

    private

    def validate_inputs(source_path, destination_path)
      if source_path.blank? || destination_path.blank?
        return Util.error(:error, 'Source and destination paths must be present.')
      end

      ServiceResult.success(result: { source_path:, destination_path: })
    end

    def build_origin_urls(source_path:, destination_path:)
      escaped_username = CGI.escapeURIComponent(@storage.username)

      source_url = Util.join_uri_path(
        @storage.uri,
        "remote.php/dav/files",
        escaped_username,
        Util.escape_path(source_path)
      )

      destination_url = Util.join_uri_path(
        @storage.uri,
        "remote.php/dav/files",
        escaped_username,
        Util.escape_path(destination_path)
      )

      { source_url:, destination_url: }
    end

    def remote_folder_does_not_exist?(destination_url)
      response = OpenProject.httpx.basic_auth(@storage.username, @storage.password).head(destination_url)

      case response
      in { status: 200..299 }
        Util.error(:conflict, 'Destination folder already exists.')
      in { status: 401 }
        Util.error(:unauthorized, "unauthorized (validate_destination)")
      in { status: 404 }
        ServiceResult.success
      else
        Util.error(:unknown, "Unexpected response (validate_destination): #{response.code}", response)
      end
    end

    def copy_folder(source_url:, destination_url:)
      response = OpenProject
        .httpx
        .basic_auth(@storage.username, @storage.password)
        .request('COPY', source_url, headers: { 'Destination' => destination_url, 'Depth' => 'infinity' })

      case response
      in { status: 200..299 }
        ServiceResult.success(message: 'Folder was successfully copied')
      in { status: 401 }
        Util.error(:unauthorized, "Unauthorized (copy_folder)")
      in { status: 404 }
        Util.error(:not_found, "Project folder not found (copy_folder)")
      in { status: 409 }
        Util.error(:conflict, Util.error_text_from_response(response))
      else
        Util.error(:unknown, "Unexpected response (copy_folder): #{response.status}", response)
      end
    end

    def get_folder_id(destination_path)
      Storages::Peripherals::Registry
        .resolve("#{@storage.short_provider_type}.queries.file_ids")
        .call(storage: @storage, path: destination_path)
    end
  end
end

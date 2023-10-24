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

module Storages::Peripherals::StorageInteraction::Nextcloud
  class CopyTemplateFolderCommand
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @uri = storage.uri
      @username = storage.username
      @password = storage.password
    end

    def self.call(storage:, source_path:, destination_path:)
      new(storage).call(source_path:, destination_path:)
    end

    def call(source_path:, destination_path:)
      validate_inputs(source_path, destination_path) >>
        build_origin_paths >>
        validate_destination >>
        copy_folder
    end

    def validate_inputs(source_path, destination_path)
      if source_path.blank? || destination_path.blank?
        return Util.error(:error, 'Source and destination paths must be present.')
      end

      ServiceResult.success(result: { source_path:, destination_path: })
    end

    def build_origin_paths
      ->(input) do
        escaped_username = CGI.escapeURIComponent(@username)

        source = Util.join_uri_path(
          @uri,
          "remote.php/dav/files",
          escaped_username,
          Util.escape_path(input[:source_path])
        )

        destination = Util.join_uri_path(
          @uri,
          "remote.php/dav/files",
          escaped_username,
          Util.escape_path(input[:destination_path])
        )

        ServiceResult.success(result: { source_url: source, destination_url: destination })
      end
    end

    def validate_destination
      ->(urls) do
        request = Net::HTTP::Head.new(urls[:destination_url])
        request.initialize_http_header Util.basic_auth_header(@username, @password)

        response = Util
                     .httpx
                     .basic_auth(@username, @password)
                     .head(urls[:destination_url])

        case response.status
        when 200
          Util.error(:conflict, 'Destination folder already exists.')
        when 401
          Util.error(:unauthorized, "unauthorized (validate_destination)")
        when 404
          ServiceResult.success(result: urls)
        else
          Util.error(:unknown, "Unexpected response (validate_destination): #{response.code}", response)
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def copy_folder
      ->(urls) do
        response = Util
                     .httpx
                     .basic_auth(@username, @password)
                     .request("COPY",
                              urls[:source_url],
                              headers: {
                                'Destination' => urls[:destination_url],
                                'Depth' => 'infinity',
                              })

        case response.status
        when 201
          ServiceResult.success(message: 'Folder was successfully copied')
        when 401
          Util.error(:unauthorized, "Unauthorized (copy_folder)")
        when 404
          Util.error(:not_found, "Project folder not found (copy_folder)")
        when 409
          Util.error(:conflict, Util.error_text_from_response(response))
        else
          Util.error(:unknown, "Unexpected response (copy_folder): #{response.status}", response)
        end
      end
    end

    # rubocop:enable Metrics/AbcSize
  end
end

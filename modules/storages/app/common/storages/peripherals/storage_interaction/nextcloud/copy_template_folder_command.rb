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
      @uri = URI(storage.host).normalize
      @username = storage.username
      @password = storage.password
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

        response = Util.http(@uri).request(request)

        case response
        when Net::HTTPSuccess
          Util.error(:conflict, 'Destination folder already exists.')
        when Net::HTTPUnauthorized
          Util.error(:not_authorized, "Not authorized (validate_destination)")
        when Net::HTTPNotFound
          ServiceResult.success(result: urls)
        else
          Util.error(:unknown, "Unexpected response (validate_destination): #{response.code}", response)
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def copy_folder
      ->(urls) do
        headers = Util.basic_auth_header(@username, @password)
        headers['Destination'] = urls[:destination_url]
        headers['Depth'] = 'infinity'

        request = Net::HTTP::Copy.new(urls[:source_url], headers)
        response = Util.http(@uri).request(request)

        case response
        when Net::HTTPCreated
          ServiceResult.success(message: 'Folder was successfully copied')
        when Net::HTTPUnauthorized
          Util.error(:not_authorized, "Not authorized (copy_folder)")
        when Net::HTTPNotFound
          Util.error(:not_found, "Project folder not found (copy_folder)")
        when Net::HTTPConflict
          Util.error(:conflict, Util.error_text_from_response(response))
        else
          Util.error(:unknown, "Unexpected response (copy_folder): #{response.code}", response)
        end
      end
    end

    # rubocop:enable Metrics/AbcSize
  end
end

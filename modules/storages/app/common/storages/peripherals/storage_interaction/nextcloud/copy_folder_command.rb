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
  class CopyFolderCommand
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @storage = storage
    end

    # rubocop:disable Metrics/AbcSize
    def call(source_folder_path, destination_folder_path)
      source = Util.join_uri_path(
        @storage.host,
        "remote.php/dav/files",
        CGI.escapeURIComponent(@storage.username),
        Util.escape_path(source_folder_path)
      )
      destination = Util.join_uri_path(
        @storage.host,
        "remote.php/dav/files",
        CGI.escapeURIComponent(@storage.username),
        Util.escape_path(destination_folder_path)
      )

      request = Net::HTTP::Copy.new(source)
      request['Destination'] = destination
      request.initialize_http_header Util.basic_auth_header(@storage.username, @storage.password)

      response = Util.http(@storage.host).request(request)

      case response
      when Net::HTTPSuccess
        ServiceResult.success(message: 'Folder was successfully copied.')
      when Net::HTTPUnauthorized
        Util.error(:not_authorized)
      when Net::HTTPNotFound
        Util.error(:not_found)
      when Net::HTTPConflict
        Util.error(:conflict, error_text_from_response(response))
      else
        Util.error(:unknown)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end

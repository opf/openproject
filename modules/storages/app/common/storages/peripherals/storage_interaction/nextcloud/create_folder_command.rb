# frozen_string_literal: true

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
  class CreateFolderCommand
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @uri = storage.uri
      @username = storage.username
      @password = storage.password
    end

    def self.call(storage:, folder_path:)
      new(storage).call(folder_path:)
    end

    # rubocop:disable Metrics/AbcSize
    def call(folder_path:)
      response = OpenProject
                   .httpx
                   .basic_auth(@username, @password)
                   .mkcol(
                     Util.join_uri_path(
                       @uri,
                       "remote.php/dav/files",
                       CGI.escapeURIComponent(@username),
                       Util.escape_path(folder_path)
                     )
                   )

      error_data = Storages::StorageErrorData.new(source: self.class, payload: response)

      case response
      in { status: 200..299 }
        ServiceResult.success(message: "Folder was successfully created.")
      in { status: 405 }
        if Util.error_text_from_response(response) == "The resource you tried to create already exists"
          ServiceResult.success(message: "Folder already exists.")
        else
          Util.error(:not_allowed, "Outbound request method not allowed", error_data)
        end
      in { status: 401 }
        Util.error(:unauthorized, "Outbound request not authorized", error_data)
      in { status: 404 }
        Util.error(:not_found, "Outbound request destination not found", error_data)
      in { status: 409 }
        Util.error(:conflict, Util.error_text_from_response(response), error_data)
      else
        Util.error(:error, "Outbound request failed", error_data)
      end
    end

    # rubocop:enable Metrics/AbcSize
  end
end

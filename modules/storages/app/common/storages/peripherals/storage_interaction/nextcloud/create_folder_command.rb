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

    Auth = ::Storages::Peripherals::StorageInteraction::Authentication

    def self.call(storage:, auth_strategy:, folder_name:, parent_location:)
      new(storage).call(auth_strategy:, folder_name:, parent_location:)
    end

    def initialize(storage)
      @storage = storage
    end

    def call(auth_strategy:, folder_name:, parent_location:)
      origin_user_id = Util.origin_user_id(caller: self.class, storage: @storage, auth_strategy:)
      if origin_user_id.failure?
        return origin_user_id
      end

      folder_path = Util.join_uri_path(parent_location, folder_name)

      Auth[auth_strategy].call(storage: @storage) do |http|
        request_url = Util.join_uri_path(@storage.uri,
                                         "remote.php/dav/files",
                                         CGI.escapeURIComponent(origin_user_id.result),
                                         Util.escape_path(folder_path))

        handle_response http.mkcol(request_url)
      end
    end

    private

    def handle_response(response)
      case response
      in { status: 200..299 }
        ServiceResult.success(message: "Folder was successfully created.")
      in { status: 405 }
        if Util.error_text_from_response(response) == "The resource you tried to create already exists"
          ServiceResult.success(message: "Folder already exists.")
        else
          Util.failure(code: :not_allowed,
                       data: Util.error_data_from_response(caller: self.class, response:),
                       log_message: "Outbound request method not allowed!")
        end
      in { status: 401 }
        Util.failure(code: :unauthorized,
                     data: Util.error_data_from_response(caller: self.class, response:),
                     log_message: "Outbound request not authorized!")
      in { status: 404 }
        Util.failure(code: :not_found,
                     data: Util.error_data_from_response(caller: self.class, response:),
                     log_message: "Outbound request destination not found!")
      in { status: 409 }
        Util.failure(code: :conflict,
                     data: Util.error_data_from_response(caller: self.class, response:),
                     log_message: Util.error_text_from_response(response))
      else
        Util.failure(code: :error,
                     data: Util.error_data_from_response(caller: self.class, response:),
                     log_message: "Outbound request failed with unknown error!")
      end
    end
  end
end

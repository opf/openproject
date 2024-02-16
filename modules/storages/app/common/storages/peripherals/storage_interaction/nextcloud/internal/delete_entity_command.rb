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

module Storages::Peripherals::StorageInteraction::Nextcloud::Internal
  class DeleteEntityCommand
    UTIL = ::Storages::Peripherals::StorageInteraction::Nextcloud::Util

    def initialize(storage)
      @uri = storage.uri
      @username = storage.username
      @password = storage.password
    end

    def self.call(storage:, location:)
      new(storage).call(location:)
    end

    def call(location:)
      response = OpenProject
                   .httpx
                   .basic_auth(@username, @password)
                   .delete(UTIL.join_uri_path(@uri,
                                              "remote.php/dav/files",
                                              CGI.escapeURIComponent(@username),
                                              UTIL.escape_path(location)))

      case response
      in { status: 200..299 }
        ServiceResult.success
      in { status: 404 }
        UTIL.error(:not_found)
      in { status: 401 }
        UTIL.error(:unauthorized)
      else
        UTIL.error(:error)
      end
    end
  end
end

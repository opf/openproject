#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# This class provides definitions for API routes and endpoints for the storages namespace. It inherits the
# functionality from the Grape REST API framework. It is mounted in lib/api/v3/root.rb.
# `modules/storages/lib/` is a defined root directory for grape, providing a root level look up for the namespaces.
# Hence, the modules of the class have to be represented in the directory structure.
module API
  module V3
    module Storages
      URN_CONNECTION_CONNECTED = "#{::API::V3::URN_PREFIX}storages:authorization:Connected".freeze
      URN_CONNECTION_AUTH_FAILED = "#{::API::V3::URN_PREFIX}storages:authorization:FailedAuthorization".freeze
      URN_CONNECTION_ERROR = "#{::API::V3::URN_PREFIX}storages:authorization:Error".freeze

      class StorageAuthorizer
        class << self
          def authorize(storage)
            oauth_client = storage.oauth_client
            connection_manager = ::OAuthClients::ConnectionManager.new(user: User.current, oauth_client:)
            case connection_manager.authorization_state
            when :connected
              URN_CONNECTION_CONNECTED
            when :failed_authorization
              URN_CONNECTION_AUTH_FAILED
            else
              URN_CONNECTION_ERROR
            end
          end
        end
      end
    end
  end
end

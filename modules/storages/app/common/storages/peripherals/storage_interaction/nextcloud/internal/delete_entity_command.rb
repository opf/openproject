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
    Util = ::Storages::Peripherals::StorageInteraction::Nextcloud::Util
    Auth = ::Storages::Peripherals::StorageInteraction::Authentication

    def self.call(storage:, auth_strategy:, location:)
      new(storage).call(auth_strategy:, location:)
    end

    def initialize(storage)
      @storage = storage
    end

    def call(auth_strategy:, location:)
      origin_user_id = origin_user_id(auth_strategy)
      if origin_user_id.failure?
        return origin_user_id
      end

      response = Auth[auth_strategy].call(storage: @storage) do |http|
        http.delete(Util.join_uri_path(@storage.uri,
                                       "remote.php/dav/files",
                                       CGI.escapeURIComponent(origin_user_id.result),
                                       Util.escape_path(location)))
      end

      case response
      in { status: 200..299 }
        ServiceResult.success
      in { status: 404 }
        failure(code: :not_found,
                payload: response.json(symbolize_keys: true),
                log_message: "Outbound request destination not found!")
      in { status: 401 }
        failure(code: :unauthorized,
                payload: response.json(symbolize_keys: true),
                log_message: "Outbound request not authorized!")
      else
        failure(code: :error,
                payload: response.json(symbolize_keys: true),
                log_message: "Outbound request failed with unknown error!")
      end
    end

    private

    def origin_user_id(auth_strategy)
      case auth_strategy.key
      when :basic_auth
        ServiceResult.success(result: @storage.username)
      when :oauth_user_token
        origin_user_id = OAuthClientToken.find_by(user_id: user, oauth_client_id: @storage.oauth_client.id)&.origin_user_id
        origin_user_id.present? ?
          ServiceResult.success(result: origin_user_id) :
          failure(code: :error,
                  payload: nil,
                  log_message: "No origin user ID or user token found. Cannot execute query without user context.")
      else
        failure(code: :error,
                payload: nil,
                log_message: "No authentication strategy with user context found. " \
                             "Cannot execute query without user context.")
      end
    end

    def failure(code:, payload:, log_message:)
      ServiceResult.failure(
        result: code,
        errors: ::Storages::StorageError.new(code:,
                                             data: ::Storages::StorageErrorData.new(source: self.class, payload:),
                                             log_message:)
      )
    end
  end
end

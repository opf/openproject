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
  class GroupUsersQuery
    using Storages::Peripherals::ServiceResultRefinements

    AUTH = ::Storages::Peripherals::StorageInteraction::Authentication

    def initialize(storage)
      @storage = storage
    end

    def self.call(storage:, group: storage.group)
      new(storage).call(group:)
    end

    def call(group:)
      AUTH.with_basic_auth(storage: @storage, http_options: Util.ocs_api_request) do |http|
        response = http.get(Util.join_uri_path(@storage.uri, "ocs/v1.php/cloud/groups", CGI.escapeURIComponent(group)))
        handle_errors(response)
      end
    end

    private

    def handle_errors(response)
      error_data = Storages::StorageErrorData.new(source: self.class, payload: response)

      case response
      in { status: 200..299 }
        group_users = Nokogiri::XML(response.body.to_s)
                        .xpath('/ocs/data/users/element')
                        .map(&:text)
        ServiceResult.success(result: group_users)
      in { status: 405 }
        Util.error(:not_allowed, 'Outbound request method not allowed', error_data)
      in { status: 401 }
        Util.error(:unauthorized, 'Outbound request not authorized', error_data)
      in { status: 404 }
        Util.error(:not_found, 'Outbound request destination not found', error_data)
      in { status: 409 }
        Util.error(:conflict, error_text_from_response(response), error_data)
      else
        Util.error(:error, 'Outbound request failed', error_data)
      end
    end
  end
end

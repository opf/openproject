# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module Storages
  module Peripherals
    module StorageInteraction
      module Nextcloud
        class GroupUsersQuery
          include TaggedLogging

          def self.call(storage:, auth_strategy:, group:)
            new(storage).call(auth_strategy:, group:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, group:)
            with_tagged_logger do
              Authentication[auth_strategy].call(storage: @storage, http_options:) do |http|
                url = UrlBuilder.url(@storage.uri, "ocs/v1.php/cloud/groups", group)
                info "Requesting user list for group #{group} via url #{url} "

                handle_response(http.get(url))
              end
            end
          end

          private

          def http_options
            Util.ocs_api_request
          end

          def handle_response(response)
            error_data = StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200..299 }
              handle_success_response(response)
            in { status: 405 }
              Util.error(:not_allowed, "Outbound request method not allowed", error_data)
            in { status: 401 }
              Util.error(:unauthorized, "Outbound request not authorized", error_data)
            in { status: 404 }
              Util.error(:not_found, "Outbound request destination not found", error_data)
            in { status: 409 }
              Util.error(:conflict, error_text_from_response(response), error_data)
            else
              Util.error(:error, "Outbound request failed", error_data)
            end
          end

          def handle_success_response(response)
            error_data = StorageErrorData.new(source: self.class, payload: response)
            xml = Nokogiri::XML(response.body.to_s)
            statuscode = xml.xpath("/ocs/meta/statuscode").text

            case statuscode
            when "100"
              group_users = xml.xpath("/ocs/data/users/element").map(&:text)
              info "#{group_users.size} users found"
              ServiceResult.success(result: group_users)
            when "404"
              Util.error(:group_does_not_exist, "Group does not exist", error_data)
            else
              Util.error(:error, "Unknown response body", error_data)
            end
          end
        end
      end
    end
  end
end

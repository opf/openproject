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

module Storages
  module Peripherals
    module StorageInteraction
      module Nextcloud
        class AddUserToGroupCommand
          def initialize(storage)
            @storage = storage
            @username = storage.username
            @password = storage.password
            @group = storage.group
          end

          # rubocop:disable Metrics/AbcSize
          def self.call(storage:, user:, group: storage.group)
            new(storage).call(user:, group:)
          end

          def call(user:, group: @group)
            response = OpenProject
                         .httpx
                         .basic_auth(@username, @password)
                         .with(headers: { "OCS-APIRequest" => "true" })
                         .post(
                           RequestUrlBuilder.build(@storage,
                                                   "ocs/v1.php/cloud/users",
                                                   user,
                                                   "groups"),
                           form: { "groupid" => CGI.escapeURIComponent(group) }
                         )

            error_data = StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200..299 }
              statuscode = Nokogiri::XML(response.body.to_s).xpath("/ocs/meta/statuscode").text

              case statuscode
              when "100"
                ServiceResult.success(message: "User has been added successfully")
              when "101"
                Util.error(:error, "No group specified", error_data)
              when "102"
                Util.error(:error, "Group does not exist", error_data)
              when "103"
                Util.error(:error, "User does not exist", error_data)
              when "104"
                Util.error(:error, "Insufficient privileges", error_data)
              when "105"
                Util.error(:error, "Failed to add user to group", error_data)
              end
            in { status: 405 }
              Util.error(:not_allowed, "Outbound request method not allowed", error_data)
            in { status: 401 }
              Util.error(:not_found, "Outbound request destination not found", error_data)
            in { status: 404 }
              Util.error(:unauthorized, "Outbound request not authorized", error_data)
            in { status: 409 }
              Util.error(:conflict, Util.error_text_from_response(response), error_data)
            else
              Util.error(:error, "Outbound request failed", error_data)
            end
          end

          # rubocop:enable Metrics/AbcSize
        end
      end
    end
  end
end

# frozen_string_literal: true

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
  class RemoveUserFromGroupCommand
    def initialize(storage)
      @uri = storage.uri
      @username = storage.username
      @password = storage.password
      @group = storage.group
    end

    def self.call(storage:, user:, group: storage.group)
      new(storage).call(user:, group:)
    end

    # rubocop:disable Metrics/AbcSize
    def call(user:, group: @group)
      response = Util.http(@uri).delete(
        Util.join_uri_path(@uri.path,
                           "ocs/v1.php/cloud/users",
                           CGI.escapeURIComponent(user),
                           "groups?groupid=#{CGI.escapeURIComponent(group)}"),
        Util.basic_auth_header(@username, @password).merge(
          'OCS-APIRequest' => 'true'
        )
      )

      case response
      when Net::HTTPSuccess
        statuscode = Nokogiri::XML(response.body).xpath('/ocs/meta/statuscode').text
        case statuscode
        when "100"
          ServiceResult.success(message: "User has been removed from group")
        when "101"
          Util.error(:error, "No group specified", response)
        when "102"
          Util.error(:error, "Group does not exist", response)
        when "103"
          Util.error(:error, "User does not exist", response)
        when "104"
          Util.error(:error, "Insufficient privileges", response)
        when "105"
          message = Nokogiri::XML(response.body).xpath('/ocs/meta/message').text
          Util.error(:error, "Failed to remove user #{user} from group #{group}: #{message}", response)
        end
      when Net::HTTPMethodNotAllowed
        Util.error(:not_allowed, 'Outbound request method not allowed', response)
      when Net::HTTPNotFound
        Util.error(:not_found, 'Outbound request destination not found', response)
      when Net::HTTPUnauthorized
        Util.error(:unauthorized, 'Outbound request not authorized', response)
      when Net::HTTPConflict
        Util.error(:conflict, Util.error_text_from_response(response), response)
      else
        Util.error(:error, 'Outbound request failed', response)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end

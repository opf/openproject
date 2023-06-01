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
  class GroupUsersQuery
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @uri = URI(storage.host).normalize
      @username = storage.username
      @password = storage.password
      @group = storage.group
    end

    # rubocop:disable Metrics/AbcSize
    def call(group: @group)
      response = Util.http(@uri).get(
        Util.join_uri_path(@uri, "ocs/v1.php/cloud/groups", CGI.escapeURIComponent(group)),
        Util.basic_auth_header(@username, @password).merge('OCS-APIRequest' => 'true')
      )
      case response
      when Net::HTTPSuccess
        group_users = Nokogiri::XML(response.body)
                        .xpath('/ocs/data/users/element')
                        .map(&:text)
        ServiceResult.success(result: group_users)
      when Net::HTTPMethodNotAllowed
        Util.error(:not_allowed)
      when Net::HTTPUnauthorized
        Util.error(:not_authorized)
      when Net::HTTPNotFound
        Util.error(:not_found)
      when Net::HTTPConflict
        Util.error(:conflict, error_text_from_response(response))
      else
        Util.error(:error)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end

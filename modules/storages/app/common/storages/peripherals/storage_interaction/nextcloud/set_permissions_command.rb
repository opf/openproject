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
  class SetPermissionsCommand < Storages::Peripherals::StorageInteraction::StorageCommand
    include API::V3::Utilities::PathHelper
    include Errors
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(base_uri:, username:, password:)
      super()

      @uri = base_uri
      @base_path = api_v3_paths.join_uri_path(@uri.path, "remote.php/dav/files", escape_whitespace(username))
      @username = username
      @password = password
    end

    def execute(folder:, permissions:)
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = @uri.scheme == 'https'

      response = http.proppatch(
        "#{@base_path}#{requested_folder(folder)}",
        converted_permissions(username: @username, permissions:),
        {
          'Authorization' => "Basic #{Base64::encode64("#{@username}:#{@password}")}"
        }
      )

      response.is_a?(Net::HTTPSuccess) ? ServiceResult.success : error(response)
    end

    private

    def escape_whitespace(value)
      value.gsub(' ', '%20')
    end

    def requested_folder(folder)
      return '' if folder.nil?

      escape_whitespace(folder)
    end

    def error(response)
      case response
      when Net::HTTPNotFound
        error_result(:not_found)
      when Net::HTTPUnauthorized
        error_result(:not_authorized)
      else
        error_result(:error)
      end
    end

    def error_result(code, log_message = nil, data = nil)
      ServiceResult.failure(
        result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
        errors: Storages::StorageError.new(code:, log_message:, data:)
      )
    end

    def converted_permissions(username:, permissions:)
      Nokogiri::XML::Builder.new do |xml|
        xml['d'].propertyupdate(
          'xmlns:d' => 'DAV:',
          'xmlns:nc' => 'http://nextcloud.org/ns'
        ) do
          xml['d'].set do
            xml['d'].prop do
              xml['nc'].send('acl-list') do
                control_user_permissions(username, xml)
                control_group_permissions(xml)
                user_permissions(xml, permissions)
              end
            end
          end
        end
      end.to_xml
    end

    def control_user_permissions(username, xml)
      xml['nc'].acl do
        xml['nc'].send('acl-mapping-type', 'user')
        xml['nc'].send('acl-mapping-id', username)
        xml['nc'].send('acl-mask', '31')
        xml['nc'].send('acl-permissions', '31')
      end
    end

    def control_group_permissions(xml)
      xml['nc'].acl do
        xml['nc'].send('acl-mapping-type', 'group')
        xml['nc'].send('acl-mapping-id', 'OpenProject')
        xml['nc'].send('acl-mask', '31')
        xml['nc'].send('acl-permissions', '0')
      end
    end

    PERMISSION_MAP = {
      read_files: 1,
      write_files: 2,
      create_files: 4,
      delete_files: 8,
      share_files: 16
    }.freeze

    def user_permissions(xml, permissions)
      permissions.each do |permission|
        username = permission[:origin_user_id]
        assignable_permission = nextcloud_permission(permission[:permissions])

        xml['nc'].acl do
          xml['nc'].send('acl-mapping-type', 'user')
          xml['nc'].send('acl-mapping-id', username)
          xml['nc'].send('acl-mask', '31')
          xml['nc'].send('acl-permissions', assignable_permission)
        end
      end
    end

    def nextcloud_permission(permission)
      permission.reduce(0) do |acc, (k, v)|
        acc = acc + PERMISSION_MAP[k] if v
        acc
      end
    end
  end
end

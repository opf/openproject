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
  class SetPermissionsCommand
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      @storage = storage
      @username = storage.username
      @password = storage.password
    end

    def self.call(storage:, path:, permissions:)
      new(storage).call(path:, permissions:)
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/PerceivedComplexity
    def call(path:, permissions:)
      raise ArgumentError if path.blank?

      users_permissions = permissions.fetch(:users)
      groups_permissions = permissions.fetch(:groups)

      body = Nokogiri::XML::Builder.new do |xml|
        xml["d"].propertyupdate(
          "xmlns:d" => "DAV:",
          "xmlns:nc" => "http://nextcloud.org/ns"
        ) do
          xml["d"].set do
            xml["d"].prop do
              xml["nc"].send(:"acl-list") do
                groups_permissions.each do |group, group_permissions|
                  xml["nc"].acl do
                    xml["nc"].send(:"acl-mapping-type", "group")
                    xml["nc"].send(:"acl-mapping-id", group)
                    xml["nc"].send(:"acl-mask", "31")
                    xml["nc"].send(:"acl-permissions", group_permissions.to_s)
                  end
                end
                users_permissions.each do |user, user_permissions|
                  xml["nc"].acl do
                    xml["nc"].send(:"acl-mapping-type", "user")
                    xml["nc"].send(:"acl-mapping-id", user)
                    xml["nc"].send(:"acl-mask", "31")
                    xml["nc"].send(:"acl-permissions", user_permissions.to_s)
                  end
                end
              end
            end
          end
        end
      end.to_xml

      response = OpenProject
                   .httpx
                   .basic_auth(@username, @password)
                   .request(
                     "PROPPATCH",
                     Storages::Peripherals::StorageInteraction::RequestUrlBuilder
                       .build(@storage, "remote.php/dav/files", @username, path),
                     xml: body
                   )

      error_data = Storages::StorageErrorData.new(source: self.class, payload: response)

      case response
      in { status: 200..299 }
        doc = Nokogiri::XML(response.body.to_s)
        if doc.xpath("/d:multistatus/d:response/d:propstat[d:status[text() = 'HTTP/1.1 200 OK']]/d:prop/nc:acl-list").present?
          ServiceResult.success(result: :success)
        else
          Util.error(:error, "nc:acl properly has not been set for #{path}", error_data)
        end
      in { status: 404 }
        Util.error(:not_found, "Outbound request destination not found", error_data)
      in { status: 401 }
        Util.error(:unauthorized, "Outbound request not authorized", error_data)
      else
        Util.error(:error, "Outbound request failed", error_data)
      end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

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
        class SetPermissionsCommand
          using ServiceResultRefinements

          SUCCESS_XPATH = "/d:multistatus/d:response/d:propstat[d:status[text() = 'HTTP/1.1 200 OK']]/d:prop/nc:acl-list"
          def self.call(storage:, path:, permissions:)
            new(storage).call(path:, permissions:)
          end

          def initialize(storage)
            @storage = storage
            @username = storage.username
            @password = storage.password
          end

          def call(path:, permissions:)
            if path.blank?
              return ServiceResult.failure(errors: StorageError.new(code: :invalid_path))
            end

            with_tagged_logger do
              info "Setting permissions #{permissions.inspect} on #{path}"

              body = request_xml_body(permissions[:groups], permissions[:users])
              # This can raise KeyErrors, we probably should just default to enpty Arrays.
              response = OpenProject
                .httpx
                .basic_auth(@username, @password)
                .request(
                  "PROPPATCH",
                  UrlBuilder.url(@storage.uri, "remote.php/dav/files", @username, path),
                  xml: body
                )

              handle_response(response)
            end
          end

          private

          # rubocop:disable Metrics/AbcSize
          def handle_response(response)
            error_data = StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200..299 }
              doc = Nokogiri::XML(response.body.to_s)
              if doc.xpath(SUCCESS_XPATH).present?
                info "Permissions set"
                ServiceResult.success(result: :success)
              else
                Util.error(:permission_not_set, "nc:acl properly has not been set for #{path}", error_data)
              end
            in { status: 404 }
              Util.error(:not_found, "Outbound request destination not found", error_data)
            in { status: 401 }
              Util.error(:unauthorized, "Outbound request not authorized", error_data)
            else
              Util.error(:error, "Outbound request failed", error_data)
            end
          end

          def request_xml_body(groups_permissions, users_permissions)
            Nokogiri::XML::Builder.new do |xml|
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
          end
          # rubocop:enable Metrics/AbcSize

          def with_tagged_logger(&)
            Rails.logger.tagged(self.class, &)
          end

          def info(message)
            Rails.logger.info message
          end
        end
      end
    end
  end
end

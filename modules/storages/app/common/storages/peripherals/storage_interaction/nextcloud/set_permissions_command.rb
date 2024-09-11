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
        # TODO: refactor to be consistent with OneDrive::SetPermissionsCommand interface
        # And streamline test cases.
        class SetPermissionsCommand
          include TaggedLogging
          using ServiceResultRefinements

          SUCCESS_XPATH = "/d:multistatus/d:response/d:propstat[d:status[text() = 'HTTP/1.1 200 OK']]/d:prop/nc:acl-list"

          def self.call(storage:, auth_strategy:, path:, permissions:)
            new(storage).call(auth_strategy:, path:, permissions:)
          end

          def initialize(storage)
            @storage = storage
          end

          # rubocop:disable Metrics/AbcSize
          def call(auth_strategy:, path:, permissions:)
            validate_input_data(path).on_failure { return _1 }

            username = Util.origin_user_id(caller: self.class, storage: @storage, auth_strategy:)
                           .on_failure { return _1 }
                           .result

            Authentication[auth_strategy].call(storage: @storage) do |http|
              with_tagged_logger do
                info "Setting permissions #{permissions.inspect} on #{path}"

                body = request_xml_body(permissions[:groups], permissions[:users])
                # This can raise KeyErrors, we probably should just default to empty Arrays.
                response = http
                             .request(
                               "PROPPATCH",
                               UrlBuilder.url(@storage.uri, "remote.php/dav/files", username, path),
                               xml: body
                             )

                handle_response(response)
              end
            end
          end

          # rubocop:enable Metrics/AbcSize

          private

          def validate_input_data(path)
            if path.blank?
              ServiceResult.failure(errors: StorageError.new(code: :invalid_path))
            else
              ServiceResult.success
            end
          end

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
        end
      end
    end
  end
end

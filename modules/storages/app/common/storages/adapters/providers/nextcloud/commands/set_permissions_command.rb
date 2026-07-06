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
  module Adapters
    module Providers
      module Nextcloud
        module Commands
          class SetPermissionsCommand < Base
            PERMISSIONS_MAP = { read_files: 1, write_files: 2, create_files: 4, delete_files: 8, share_files: 16 }.freeze
            PERMISSIONS_KEYS = OpenProject::Storages::Engine.external_file_permissions
            SUCCESS_XPATH = "/d:multistatus/d:response/d:propstat[d:status[text() = 'HTTP/1.1 200 OK']]/d:prop/nc:acl-list"

            # rubocop:disable Metrics/AbcSize
            def call(auth_strategy:, input_data:)
              username = origin_user_id(auth_strategy:).value_or { return Failure(it) }

              permissions = parse_permission_mask(input_data.user_permissions)

              Authentication[auth_strategy].call(storage: @storage) do |http|
                with_tagged_logger do
                  info "Getting the folder information"
                  Input::FileInfo.build(file_id: input_data.file_id).bind do |file_data|
                    Queries::FileInfoQuery.call(storage: @storage, auth_strategy:, input_data: file_data).bind do |folder_info|
                      info "Setting permissions #{permissions.inspect} on #{folder_info.location}"
                      body = request_xml_body(permissions[:groups], permissions[:users])
                      # This can raise KeyErrors, we probably should just default to empty Arrays.
                      response = http.request("PROPPATCH",
                                              UrlBuilder.url(@storage.uri,
                                                             "remote.php/dav/files",
                                                             username,
                                                             folder_info.location),
                                              xml: body)

                      handle_response(response)
                    end
                  end
                end
              end
            end

            # rubocop:enable Metrics/AbcSize

            private

            def parse_permission_mask(user_permissions)
              user_permissions.each_with_object({ groups: {}, users: {} }) do |entry, aggregate|
                if entry.key?(:user_id)
                  aggregate[:users][entry[:user_id]] =
                    PERMISSIONS_MAP.values_at(*(PERMISSIONS_KEYS & entry[:permissions])).sum
                else
                  aggregate[:groups][entry[:group_id]] =
                    PERMISSIONS_MAP.values_at(*(PERMISSIONS_KEYS & entry[:permissions])).sum
                end
              end
            end

            # rubocop:disable Metrics/AbcSize
            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                doc = Nokogiri::XML(response.body.to_s)
                if doc.xpath(SUCCESS_XPATH).present?
                  info "Permissions set"
                  Success(:success)
                else
                  Failure(error.with(code: :permission_not_set))
                end
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error.with(code: :error))
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
end

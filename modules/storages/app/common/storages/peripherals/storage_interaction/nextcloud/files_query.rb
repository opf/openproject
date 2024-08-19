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
        class FilesQuery
          def self.call(storage:, auth_strategy:, folder:)
            new(storage).call(auth_strategy:, folder:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, folder:)
            validate_input_data(auth_strategy, folder).on_failure { return _1 }

            origin_user = Util.origin_user_id(caller: self.class, storage: @storage, auth_strategy:)
                              .on_failure { return _1 }
                              .result

            @location_prefix = CGI.unescape UrlBuilder.path(@storage.uri.path, "remote.php/dav/files", origin_user)

            result = make_request(auth_strategy:, folder:, origin_user:)
            storage_files(result)
          end

          private

          def validate_input_data(auth_strategy, folder)
            error_data = StorageErrorData.new(source: self.class)

            if auth_strategy.user.nil?
              Util.error(:error, "Cannot execute query without user context.", error_data)
            elsif folder.is_a?(ParentFolder)
              ServiceResult.success
            else
              Util.error(:error, "Folder input is not a ParentFolder object.", error_data)
            end
          end

          def make_request(auth_strategy:, folder:, origin_user:)
            Authentication[auth_strategy].call(storage: @storage,
                                               http_options: Util.webdav_request_with_depth(1)) do |http|
              response = http.request("PROPFIND",
                                      UrlBuilder.url(@storage.uri,
                                                     "remote.php/dav/files",
                                                     origin_user,
                                                     folder.path),
                                      xml: requested_properties)
              handle_response(response)
            end
          end

          def handle_response(response)
            error_data = StorageErrorData.new(source: self.class, payload: response)

            case response
            in { status: 200..299 }
              ServiceResult.success(result: response.body)
            in { status: 404 }
              Util.error(:not_found, "Outbound request destination not found", error_data)
            in { status: 401 }
              Util.error(:unauthorized, "Outbound request not authorized", error_data)
            else
              Util.error(:error, "Outbound request failed", error_data)
            end
          end

          # rubocop:disable Metrics/AbcSize
          def requested_properties
            Nokogiri::XML::Builder.new do |xml|
              xml["d"].propfind(
                "xmlns:d" => "DAV:",
                "xmlns:oc" => "http://owncloud.org/ns"
              ) do
                xml["d"].prop do
                  xml["oc"].fileid
                  xml["oc"].size
                  xml["d"].getcontenttype
                  xml["d"].getlastmodified
                  xml["oc"].permissions
                  xml["oc"].send(:"owner-display-name")
                end
              end
            end.to_xml
          end

          # rubocop:enable Metrics/AbcSize

          def storage_files(response)
            response.map do |xml|
              parent, *files = Nokogiri::XML(xml)
                                       .xpath("//d:response")
                                       .to_a
                                       .map { |file_element| storage_file(file_element) }

              StorageFiles.new(files, parent, ancestors(parent.location))
            end
          end

          def ancestors(parent_location)
            path = parent_location.split("/")
            return [] if path.count == 0

            path.take(path.count - 1).reduce([]) do |list, item|
              last = list.last
              prefix = last.nil? || last.location[-1] != "/" ? "/" : ""
              location = "#{last&.location}#{prefix}#{item}"
              list.append(forge_ancestor(location))
            end
          end

          # The ancestors are simply derived objects from the parents location string. Until we have real information
          # from the nextcloud API about the path to the parent, we need to derive name, location and forge an ID.
          def forge_ancestor(location)
            StorageFile.new(id: Digest::SHA256.hexdigest(location), name: name(location), location:)
          end

          def name(location)
            location == "/" ? "Root" : CGI.unescape(location.split("/").last)
          end

          def storage_file(file_element)
            location = location(file_element)

            StorageFile.new(
              id: id(file_element),
              name: name(location),
              size: size(file_element),
              mime_type: mime_type(file_element),
              last_modified_at: last_modified_at(file_element),
              created_by_name: created_by(file_element),
              location:,
              permissions: permissions(file_element)
            )
          end

          def id(element)
            element
              .xpath(".//oc:fileid")
              .map(&:inner_text)
              .reject(&:empty?)
              .first
          end

          def location(element)
            texts = element
                    .xpath("d:href")
                    .map(&:inner_text)

            return nil if texts.empty?

            element_name = texts.first.delete_prefix(@location_prefix)

            return element_name if element_name == "/"

            element_name.delete_suffix("/")
          end

          def size(element)
            element
              .xpath(".//oc:size")
              .map(&:inner_text)
              .map { |e| Integer(e) }
              .first
          end

          def mime_type(element)
            element
              .xpath(".//d:getcontenttype")
              .map(&:inner_text)
              .reject(&:empty?)
              .first || "application/x-op-directory"
          end

          def last_modified_at(element)
            element
              .xpath(".//d:getlastmodified")
              .map { |e| DateTime.parse(e) }
              .first
          end

          def created_by(element)
            element
              .xpath(".//oc:owner-display-name")
              .map(&:inner_text)
              .reject(&:empty?)
              .first
          end

          def permissions(element)
            permissions_string =
              element
              .xpath(".//oc:permissions")
              .map(&:inner_text)
              .reject(&:empty?)
              .first

            # Nextcloud Dav permissions:
            # https://github.com/nextcloud/server/blob/66648011c6bc278ace57230db44fd6d63d67b864/lib/public/Files/DavUtil.php
            result = []
            result << :readable if permissions_string.include?("G")
            result << :writeable if permissions_string.match?(/W|CK/)
            result
          end
        end
      end
    end
  end
end

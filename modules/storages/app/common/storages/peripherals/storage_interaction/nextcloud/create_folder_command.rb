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
        class CreateFolderCommand
          include TaggedLogging
          using ServiceResultRefinements

          def self.call(storage:, auth_strategy:, folder_name:, parent_location:)
            new(storage).call(auth_strategy:, folder_name:, parent_location:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, folder_name:, parent_location:)
            with_tagged_logger do
              info "Trying to create folder #{folder_name} under #{parent_location} using #{auth_strategy.key}"
              origin_user_id = Util.origin_user_id(caller: self.class, storage: @storage, auth_strategy:)
                                   .on_failure { |error| return error }
                                   .result

              path_prefix = UrlBuilder.path(@storage.uri.path, "remote.php/dav/files", origin_user_id)
              request_url = UrlBuilder.url(@storage.uri,
                                           "remote.php/dav/files",
                                           origin_user_id,
                                           parent_location.path,
                                           folder_name)

              create_folder_request(auth_strategy, request_url, path_prefix)
            end
          end

          private

          def create_folder_request(auth_strategy, request_url, path_prefix)
            Authentication[auth_strategy].call(storage: @storage) do |http|
              result = handle_response(http.mkcol(request_url))
              return result if result.failure?

              handle_response(http.propfind(request_url, requested_properties)).map do |response|
                info "Folder successfully created"
                storage_file(path_prefix, response)
              end
            end
          end

          def handle_response(response)
            case response
            in { status: 200..299 }
              ServiceResult.success(result: response)
            in { status: 401 }
              Util.failure(code: :unauthorized,
                           data: Util.error_data_from_response(caller: self.class, response:),
                           log_message: "Outbound request not authorized!")
            in { status: 404 | 409 } # webDAV endpoint returns 409 if path does not exist
              Util.failure(code: :not_found,
                           data: Util.error_data_from_response(caller: self.class, response:),
                           log_message: "Outbound request destination not found!")
            in { status: 405 } # webDAV endpoint returns 405 if folder already exists
              Util.failure(code: :conflict,
                           data: Util.error_data_from_response(caller: self.class, response:),
                           log_message: "Folder already exists")
            else
              Util.failure(code: :error,
                           data: Util.error_data_from_response(caller: self.class, response:),
                           log_message: "Outbound request failed with unknown error!")
            end
          end

          def requested_properties
            Nokogiri::XML::Builder.new do |xml|
              xml["d"].propfind(
                "xmlns:d" => "DAV:",
                "xmlns:oc" => "http://owncloud.org/ns"
              ) do
                xml["d"].prop do
                  xml["oc"].fileid
                  xml["oc"].size
                  xml["d"].getlastmodified
                  xml["oc"].send(:"owner-display-name")
                end
              end
            end.to_xml
          end

          # rubocop:disable Metrics/AbcSize
          def storage_file(path_prefix, response)
            xml = response.xml
            path = xml.xpath("//d:response/d:href/text()").to_s
            timestamp = xml.xpath("//d:response/d:propstat/d:prop/d:getlastmodified/text()").to_s
            creator = xml.xpath("//d:response/d:propstat/d:prop/oc:owner-display-name/text()").to_s
            location = CGI.unescapeURIComponent(path.gsub(path_prefix, "")).delete_suffix("/")

            StorageFile.new(
              id: xml.xpath("//d:response/d:propstat/d:prop/oc:fileid/text()").to_s,
              name: location.split("/").last,
              size: xml.xpath("//d:response/d:propstat/d:prop/oc:size/text()").to_s,
              mime_type: "application/x-op-directory",
              created_at: Time.zone.parse(timestamp),
              last_modified_at: Time.zone.parse(timestamp),
              created_by_name: creator,
              last_modified_by_name: creator,
              location:
            )
          end

          # rubocop:enable Metrics/AbcSize
        end
      end
    end
  end
end

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
        module Internal
          class PropfindQuery
            # Only for information purposes currently.
            # Probably a bit later we could validate `#call` parameters.
            #
            # DEPTH = %w[0 1 infinity].freeze
            # POSSIBLE_PROPS = %w[
            #   d:getlastmodified
            #   d:getetag
            #   d:getcontenttype
            #   d:resourcetype
            #   d:getcontentlength
            #   d:permissions
            #   d:size
            #   oc:id
            #   oc:fileid
            #   oc:favorite
            #   oc:comments-href
            #   oc:comments-count
            #   oc:comments-unread
            #   oc:owner-id
            #   oc:owner-display-name
            #   oc:share-types
            #   oc:checksums
            #   oc:size
            #   nc:has-preview
            #   nc:rich-workspace
            #   nc:contained-folder-count
            #   nc:contained-file-count
            #   nc:acl-list
            # ].freeze

            def self.call(storage:, http:, username:, path:, props:)
              new(storage).call(http:, username:, path:, props:)
            end

            def initialize(storage)
              @storage = storage
            end

            def call(http:, username:, path:, props:)
              request_uri = UrlBuilder.url(@storage.uri, "remote.php/dav/files", username, path)
              response = http.request(:propfind, request_uri, xml: request_body(props))

              handle_response(response, username)
            end

            private

            def handle_response(response, username)
              case response
              in { status: 200..299 }
                success_result(response, username)
              in { status: 401 }
                Util.failure(code: :unauthorized,
                             data: Util.error_data_from_response(caller: self.class, response:),
                             log_message: "Outbound request not authorized!")
              in { status: 404 }
                Util.failure(code: :not_found,
                             data: Util.error_data_from_response(caller: self.class, response:),
                             log_message: "Outbound request destination not found!")
              in { status: 405 }
                Util.failure(code: :not_allowed,
                             data: Util.error_data_from_response(caller: self.class, response:),
                             log_message: "Outbound request method not allowed!")

              else
                Util.failure(code: :error,
                             data: Util.error_data_from_response(caller: self.class, response:),
                             log_message: "Outbound request failed with unknown error!")
              end
            end

            # rubocop:disable Metrics/AbcSize
            def success_result(response, username)
              doc = Nokogiri::XML(response.body.to_s)
              result = {}
              doc.xpath("/d:multistatus/d:response").each do |resource_section|
                resource = resource_path(resource_section, username)
                result[resource] = {}

                # In future it could be useful to respond not only with found, but not found props as well
                # resource_section.xpath("d:propstat[d:status[text() = 'HTTP/1.1 404 Not Found']]/d:prop/*")
                resource_section.xpath("d:propstat[d:status[text() = 'HTTP/1.1 200 OK']]/d:prop/*").each do |node|
                  result[resource][node.name.to_s] = node.text.strip
                end
              end

              ServiceResult.success(result:)
            end

            # rubocop:enable Metrics/AbcSize

            def resource_path(section, username)
              path = CGI.unescape(section.xpath("d:href").text.strip)
                        .gsub!(UrlBuilder.path(@storage.uri.path, "remote.php/dav/files", username), "")

              path.end_with?("/") && path.length > 1 ? path.chop : path
            end

            def request_body(props)
              Nokogiri::XML::Builder.new do |xml|
                xml["d"].propfind(
                  "xmlns:d" => "DAV:",
                  "xmlns:oc" => "http://owncloud.org/ns",
                  "xmlns:nc" => "http://nextcloud.org/ns"
                ) do
                  xml["d"].prop do
                    props.each do |prop|
                      namespace, property = prop.split(":")
                      xml[namespace].send(property)
                    end
                  end
                end
              end.to_xml
            end
          end
        end
      end
    end
  end
end

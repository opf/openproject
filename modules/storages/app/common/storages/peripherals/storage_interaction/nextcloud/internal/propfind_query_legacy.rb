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
          class PropfindQueryLegacy
            include TaggedLogging
            def self.call(storage:, depth:, path:, props:)
              new(storage).call(depth:, path:, props:)
            end

            def initialize(storage)
              @storage = storage
              @username = storage.username
              @password = storage.password
              @group = storage.group
            end

            # rubocop:disable Metrics/AbcSize
            def call(depth:, path:, props:)
              with_tagged_logger do
                body = Nokogiri::XML::Builder.new do |xml|
                  xml["d"].propfind(
                    "xmlns:d" => "DAV:",
                    "xmlns:oc" => "http://owncloud.org/ns",
                    "xmlns:nc" => "http://nextcloud.org/ns"
                  ) do
                    xml["d"].prop do
                      props.each do |prop|
                        namespace, property = prop.split(":")
                        xml[namespace].public_send(property)
                      end
                    end
                  end
                end.to_xml

                response = OpenProject
                             .httpx
                             .basic_auth(@username, @password)
                             .with(headers: { "Depth" => depth })
                             .request(
                               "PROPFIND",
                               UrlBuilder.url(@storage.uri, "remote.php/dav/files", @username, path),
                               xml: body
                             )

                error_data = StorageErrorData.new(source: self.class, payload: response)

                case response
                in { status: 200..299 }
                  log_response(response)
                  info "Parsing XML response body"
                  doc = Nokogiri::XML(response.body.to_s)
                  info "Parsing response body"
                  result = doc.xpath("/d:multistatus/d:response").each_with_object({}) do |resource_section, hash|
                    source_path = UrlBuilder.path(@storage.uri.path, "/remote.php/dav/files", @username)
                    resource = CGI.unescape(resource_section.xpath("d:href").text.strip).gsub!(source_path, "")

                    hash[resource] = {}

                    # In future it could be useful to respond not only with found, but not found props as well
                    # resource_section.xpath("d:propstat[d:status[text() = 'HTTP/1.1 404 Not Found']]/d:prop/*")
                    resource_section.xpath("d:propstat[d:status[text() = 'HTTP/1.1 200 OK']]/d:prop/*").each do |node|
                      hash[resource][node.name.to_s] = node.text.strip
                    end
                  end

                  info "Response parsed found: #{result.inspect}"
                  ServiceResult.success(result:)
                in { status: 405 }
                  log_response(response)
                  Util.error(:not_allowed, "Outbound request method not allowed", error_data)
                in { status: 401 }
                  log_response(response)
                  Util.error(:unauthorized, "Outbound request not authorized", error_data)
                in { status: 404 }
                  log_response(response)
                  Util.error(:not_found, "Outbound request destination not found", error_data)
                else
                  Util.error(:error, "Outbound request failed", error_data)
                end
              end
            end
            # rubocop:enable Metrics/AbcSize

            def log_response(response)
              info "Storage responded with a #{response.status} code."
            end
          end
        end
      end
    end
  end
end

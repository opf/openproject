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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Providers
      module Nextcloud
        class StorageFileTransformer
          def transform_document(xml, path_prefix)
            transform_element(xml.xpath("//d:response"), path_prefix)
          end

          def transform_element(xml, path_prefix)
            location = extract_location(xml, path_prefix)

            Results::StorageFile.build(
              id: prop_text(xml, "oc:fileid"),
              name: location == "/" ? "Root" : location.split("/").last,
              size: extract_size(xml),
              mime_type: prop_text(xml, "d:getcontenttype").presence || "application/x-op-directory",
              last_modified_at: Time.zone.parse(prop_text(xml, "d:getlastmodified")),
              created_by_name: prop_text(xml, "oc:owner-display-name").presence || "Unknown",
              location:,
              permissions: parse_permissions(prop_text(xml, "oc:permissions"))
            )
          end

          # Returns the XML definition that needs to be sent to Nextcloud, so that it will respond with the required properties
          # for a successful call to #transform.
          # rubocop:disable Metrics/AbcSize
          def requested_properties
            Nokogiri::XML::Builder.new do |xml|
              xml["d"].propfind("xmlns:d" => "DAV:", "xmlns:oc" => "http://owncloud.org/ns") do
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

          private

          def prop_text(xml, prop_key)
            xml.xpath("./d:propstat/d:prop/#{prop_key}/text()").to_s
          end

          def extract_location(xml, path_prefix)
            path = xml.xpath("./d:href/text()").to_s

            location = CGI.unescapeURIComponent(UrlBuilder.path(CGI.unescapeURIComponent(path)).delete_prefix(path_prefix))
            return "/" if location == ""

            location
          end

          def extract_size(xml)
            string = prop_text(xml, "oc:size")
            return nil if string.blank?

            Integer(string)
          end

          def parse_permissions(permissions_string)
            # Nextcloud Dav permissions:
            # https://github.com/nextcloud/server/blob/66648011c6bc278ace57230db44fd6d63d67b864/lib/public/Files/DavUtil.php
            result = []
            result << :readable if permissions_string&.include?("G")
            result << :writeable if permissions_string&.match?(/W|CK/)
            result
          end
        end
      end
    end
  end
end

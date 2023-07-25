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

module Storages::Peripherals::StorageInteraction::Nextcloud::Internal
  class PropfindQuery
    UTIL = ::Storages::Peripherals::StorageInteraction::Nextcloud::Util

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

    def initialize(storage)
      @uri = URI(storage.host).normalize
      @username = storage.username
      @password = storage.password
      @group = storage.group
    end

    # rubocop:disable Metrics/AbcSize
    def call(depth:, path:, props:)
      body = Nokogiri::XML::Builder.new do |xml|
        xml['d'].propfind(
          'xmlns:d' => 'DAV:',
          'xmlns:oc' => 'http://owncloud.org/ns',
          'xmlns:nc' => 'http://nextcloud.org/ns'
        ) do
          xml['d'].prop do
            props.each do |prop|
              namespace, property = prop.split(':')
              xml[namespace].send(property)
            end
          end
        end
      end.to_xml

      response = UTIL.http(@uri).propfind(
        UTIL.join_uri_path(
          @uri,
          'remote.php/dav/files',
          CGI.escapeURIComponent(@username),
          UTIL.escape_path(path)
        ),
        body,
        UTIL.basic_auth_header(@username, @password).merge('Depth' => depth)
      )

      case response
      when Net::HTTPSuccess
        doc = Nokogiri::XML response.body
        result = {}
        doc.xpath('/d:multistatus/d:response').each do |resource_section|
          resource = CGI.unescape(resource_section.xpath("d:href").text.strip)
                        .gsub!(UTIL.join_uri_path(@uri.path, "/remote.php/dav/files/#{@username}/"), "")

          result[resource] = {}

          # In future it could be useful to respond not only with found, but not found props as well
          # resource_section.xpath("d:propstat[d:status[text() = 'HTTP/1.1 404 Not Found']]/d:prop/*")
          resource_section.xpath("d:propstat[d:status[text() = 'HTTP/1.1 200 OK']]/d:prop/*").each do |node|
            result[resource][node.name.to_s] = node.text.strip
          end
        end

        ServiceResult.success(result:)
      when Net::HTTPMethodNotAllowed
        UTIL.error(:not_allowed)
      when Net::HTTPUnauthorized
        UTIL.error(:not_authorized)
      when Net::HTTPNotFound
        UTIL.error(:not_found)
      else
        UTIL.error(:error)
      end
    end

    # rubocop:enable Metrics/AbcSize
  end
end

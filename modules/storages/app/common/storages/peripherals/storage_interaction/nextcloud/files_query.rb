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

module Storages::Peripherals::StorageInteraction::Nextcloud
  class FilesQuery
    def initialize(storage)
      @uri = URI(storage.host).normalize
      @oauth_client = storage.oauth_client
    end

    # rubocop:disable Metrics/AbcSize
    def call(user:, folder:)
      result = Util.token(user:, oauth_client: @oauth_client) do |token|
        base_path = Util.join_uri_path(@uri.path, "remote.php/dav/files")
        @location_prefix = Util.join_uri_path(base_path, token.origin_user_id.gsub(' ', '%20'))

        response = Util.http(@uri).propfind(
          Util.join_uri_path(base_path, CGI.escapeURIComponent(token.origin_user_id), requested_folder(folder)),
          requested_properties,
          {
            'Depth' => '1',
            'Authorization' => "Bearer #{token.access_token}"
          }
        )

        case response
        when Net::HTTPSuccess
          ServiceResult.success(result: response.body)
        when Net::HTTPNotFound
          Util.error(:not_found)
        when Net::HTTPUnauthorized
          Util.error(:not_authorized)
        else
          Util.error(:error)
        end
      end

      storage_files(result)
    end

    # rubocop:enable Metrics/AbcSize

    private

    def requested_folder(folder)
      return '' if folder.nil?

      Util.escape_path(folder)
    end

    # rubocop:disable Metrics/AbcSize
    def requested_properties
      Nokogiri::XML::Builder.new do |xml|
        xml['d'].propfind(
          'xmlns:d' => 'DAV:',
          'xmlns:oc' => 'http://owncloud.org/ns'
        ) do
          xml['d'].prop do
            xml['oc'].fileid
            xml['oc'].size
            xml['d'].getcontenttype
            xml['d'].getlastmodified
            xml['oc'].permissions
            xml['oc'].send('owner-display-name')
          end
        end
      end.to_xml
    end

    # rubocop:enable Metrics/AbcSize

    def storage_files(response)
      response.map do |xml|
        a = Nokogiri::XML(xml)
              .xpath('//d:response')
              .to_a

        parent, *files =
          a.map do |file_element|
            storage_file(file_element)
          end

        ::Storages::StorageFiles.new(files, parent, ancestors(parent.location))
      end
    end

    def ancestors(parent_location)
      path = parent_location.split('/')
      return [] if path.count == 0

      path.take(path.count - 1).reduce([]) do |list, item|
        last = list.last
        prefix = last.nil? || last.location[-1] != '/' ? '/' : ''
        location = "#{last&.location}#{prefix}#{item}"
        list.append(forge_ancestor(location))
      end
    end

    # The ancestors are simply derived objects from the parents location string. Until we have real information
    # from the nextcloud API about the path to the parent, we need to derive name, location and forge an ID.
    def forge_ancestor(location)
      ::Storages::StorageFile.new(id: Digest::SHA256.hexdigest(location), name: name(location), location:)
    end

    def name(location)
      location == '/' ? location : CGI.unescape(location.split('/').last)
    end

    def storage_file(file_element)
      location = location(file_element)

      ::Storages::StorageFile.new(
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
        .xpath('.//oc:fileid')
        .map(&:inner_text)
        .reject(&:empty?)
        .first
    end

    def location(element)
      texts = element
                .xpath('d:href')
                .map(&:inner_text)

      return nil if texts.empty?

      element_name = texts.first.delete_prefix(@location_prefix)

      return element_name if element_name == '/'

      element_name.delete_suffix('/')
    end

    def size(element)
      element
        .xpath('.//oc:size')
        .map(&:inner_text)
        .map { |e| Integer(e) }
        .first
    end

    def mime_type(element)
      element
        .xpath('.//d:getcontenttype')
        .map(&:inner_text)
        .reject(&:empty?)
        .first || 'application/x-op-directory'
    end

    def last_modified_at(element)
      element
        .xpath('.//d:getlastmodified')
        .map { |e| DateTime.parse(e) }
        .first
    end

    def created_by(element)
      element
        .xpath('.//oc:owner-display-name')
        .map(&:inner_text)
        .reject(&:empty?)
        .first
    end

    def permissions(element)
      permissions_string =
        element
          .xpath('.//oc:permissions')
          .map(&:inner_text)
          .reject(&:empty?)
          .first

      # Nextcloud Dav permissions:
      # https://github.com/nextcloud/server/blob/66648011c6bc278ace57230db44fd6d63d67b864/lib/public/Files/DavUtil.php
      result = []
      result << :readable if permissions_string.include?('G')
      result << :writeable if %w[CK W].reduce(false) { |s, v| s || permissions_string.include?(v) }
      result
    end
  end
end

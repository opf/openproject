#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
  class FilesQuery < Storages::Peripherals::StorageInteraction::StorageQuery
    def initialize(base_uri:, token:, with_refreshed_token:)
      super()
      @uri = base_uri
      @token = token
      @with_refreshed_token = with_refreshed_token
      @base_path = "/remote.php/dav/files/#{token.origin_user_id}"
    end

    def query(data)
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = @uri.scheme == 'https'

      result = @with_refreshed_token.call(@token) do |token|
        response = http.propfind(
          "#{@base_path}#{data}",
          requested_properties,
          {
            'Depth' => '1',
            'Authorization' => "Bearer #{token.access_token}"
          }
        )

        response.is_a?(Net::HTTPSuccess) ? ServiceResult.success(result: response.body) : error(response)
      end

      storage_files(result)
    end

    private

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
            xml['oc'].send('owner-display-name')
          end
        end
      end.to_xml
    end

    def error(response)
      case response
      when Net::HTTPNotFound
        ServiceResult.failure(result: :not_found)
      when Net::HTTPUnauthorized
        ServiceResult.failure(result: :not_authorized)
      else
        ServiceResult.failure(result: :error)
      end
    end

    def storage_files(response)
      response.map do |xml|
        Nokogiri::XML(xml)
          .xpath('//d:response')
          .drop(1) # drop current directory
          .map { |file_element| storage_file(file_element) }
      end
    end

    def storage_file(file_element)
      location = name(file_element)
      name = CGI.unescape(location.split('/').last)

      ::Storages::StorageFile.new(
        id(file_element),
        name,
        size(file_element),
        mime_type(file_element),
        nil,
        last_modified_at(file_element),
        created_by(file_element),
        nil,
        location
      )
    end

    def id(element)
      element
        .xpath('.//oc:fileid')
        .map(&:inner_text)
        .reject(&:empty?)
        .first
    end

    def name(element)
      texts = element
                .xpath('d:href')
                .map(&:inner_text)

      return nil if texts.empty?

      texts
        .first
        .delete_prefix(@base_path)
        .delete_suffix('/')
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
  end
end

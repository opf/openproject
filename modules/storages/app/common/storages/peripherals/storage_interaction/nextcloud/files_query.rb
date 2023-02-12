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
  class FilesQuery < Storages::Peripherals::StorageInteraction::StorageQuery
    def initialize(base_uri:, token:, retry_proc:)
      super()
      @uri = base_uri
      @token = token
      @retry_proc = retry_proc
      @base_path = File.join(@uri.path, "remote.php/dav/files", token.origin_user_id)
    end

    def query(parent)
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = @uri.scheme == 'https'

      result = @retry_proc.call(@token) do |token|
        response = http.propfind(
          "#{@base_path}#{requested_folder(parent)}",
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

    def requested_folder(folder)
      return '' if folder.nil?

      folder.gsub(' ', '%20')
    end

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

    def error(response)
      case response
      when Net::HTTPNotFound
        error_result(:not_found)
      when Net::HTTPUnauthorized
        error_result(:not_authorized)
      else
        error_result(:error)
      end
    end

    def error_result(code, log_message = nil, data = nil)
      ServiceResult.failure(
        result: code, # This is needed to work with the ConnectionManager token refresh mechanism.
        errors: Storages::StorageError.new(code:, log_message:, data:)
      )
    end

    def storage_files(response)
      response.map do |xml|
        a = Nokogiri::XML(xml)
              .xpath('//d:response')
              .to_a

        parent, *files =
          a.map do |file_element|
            storage_file(file_element)
          end

        ::Storages::StorageFiles.new(files, parent)
      end
    end

    def storage_file(file_element)
      location = name(file_element)
      name = location == '/' ? location : CGI.unescape(location.split('/').last)

      ::Storages::StorageFile.new(
        id(file_element),
        name,
        size(file_element),
        mime_type(file_element),
        nil,
        last_modified_at(file_element),
        created_by(file_element),
        nil,
        location,
        permissions(file_element)
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

      element_name = texts.first.delete_prefix(@base_path)

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

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
  class CreateFolderCommand < Storages::Peripherals::StorageInteraction::StorageCommand
    include API::V3::Utilities::PathHelper
    include Errors
    using Storages::Peripherals::ServiceResultRefinements

    def initialize(storage)
      super()

      @uri = URI(storage.host).normalize
      @base_path = api_v3_paths.join_uri_path(@uri.path, "remote.php/dav/files", escape_whitespace(storage.username))
      @groupfolder = storage.groupfolder
      @username = storage.username
      @password = storage.password
    end

    # rubocop:disable Metrics/AbcSize
    def execute(folder:)
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = @uri.scheme == 'https'

      response = http.mkcol(
        "#{@base_path}/#{@groupfolder}/#{requested_folder(folder)}",
        nil,
        {
          'Authorization' => "Basic #{Base64::encode64("#{@username}:#{@password}")}"
        }
      )

      case response
      when Net::HTTPSuccess
        ServiceResult.success(message: 'Folder was successfully created.')
      when Net::HTTPMethodNotAllowed
        if error_text_from_response(response) == 'The resource you tried to create already exists'
          ServiceResult.success(message: 'Folder already exists.')
        else
          error(:not_allowed)
        end
      when Net::HTTPUnauthorized
        error(:not_authorized)
      when Net::HTTPNotFound
        error(:not_found)
      when Net::HTTPConflict
        error(:conflict, error_text_from_response(response))
      else
        error(:error)
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def error_text_from_response(response)
      Nokogiri::XML(response.body).xpath("//s:message").text
    end

    def escape_whitespace(value)
      value.gsub(' ', '%20')
    end

    def requested_folder(folder)
      raise ArgumentError.new("Folder can't be nil or empty string!") if folder.blank?

      escape_whitespace(folder)
    end
  end
end

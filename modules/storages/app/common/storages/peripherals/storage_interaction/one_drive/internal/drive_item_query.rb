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
      module OneDrive
        module Internal
          class DriveItemQuery
            def initialize(storage)
              @storage = storage
            end

            def call(http:, drive_item_id:, fields: [])
              select_url_query = if fields.empty?
                                   ""
                                 else
                                   "?$select=#{fields.join(',')}"
                                 end

              make_file_request(drive_item_id, http, select_url_query)
            end

            private

            def make_file_request(drive_item_id, http, select_url_query)
              url = UrlBuilder.url(Util.drive_base_uri(@storage), uri_path_for(drive_item_id))
              handle_response http.get("#{url}#{select_url_query}")
            end

            def handle_response(response)
              case response
              in { status: 200..299 }
                ServiceResult.success(result: response.json(symbolize_keys: true))
              in { status: 404 }
                ServiceResult.failure(result: :not_found,
                                      errors: Util.storage_error(response:, code: :not_found, source: self.class))
              in { status: 403 }
                ServiceResult.failure(result: :forbidden,
                                      errors: Util.storage_error(response:, code: :forbidden, source: self.class))
              in { status: 401 }
                ServiceResult.failure(result: :unauthorized,
                                      errors: Util.storage_error(response:, code: :unauthorized, source: self.class))
              else
                data = StorageErrorData.new(source: self.class, payload: response)
                ServiceResult.failure(result: :error, errors: StorageError.new(code: :error, data:))
              end
            end

            def uri_path_for(file_id)
              if file_id == "/"
                "/root"
              else
                "/items/#{file_id}"
              end
            end
          end
        end
      end
    end
  end
end

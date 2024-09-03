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
          class ChildrenQuery
            Util = ::Storages::Peripherals::StorageInteraction::OneDrive::Util

            def initialize(storage)
              @storage = storage
            end

            def call(http:, folder:, fields: [])
              query = if fields.empty?
                        ""
                      else
                        "?$select=#{fields.join(',')}"
                      end

              make_children_request(folder, http, query)
            end

            private

            def make_children_request(folder, http, query)
              url = UrlBuilder.url(Util.drive_base_uri(@storage), uri_path_for(folder))
              handle_responses(http.get(url + query))
            end

            def handle_responses(response)
              case response
              in { status: 200..299 }
                ServiceResult.success(result: response.json(symbolize_keys: true))
              in { status: 404 }
                ServiceResult.failure(result: :not_found,
                                      errors: Util.storage_error(response:, code: :not_found, source: self))
              in { status: 403 }
                ServiceResult.failure(result: :forbidden,
                                      errors: Util.storage_error(response:, code: :forbidden, source: self))
              in { status: 401 }
                ServiceResult.failure(result: :unauthorized,
                                      errors: Util.storage_error(response:, code: :unauthorized, source: self))
              else
                data = ::Storages::StorageErrorData.new(source: self.class, payload: response)
                ServiceResult.failure(result: :error, errors: ::Storages::StorageError.new(code: :error, data:))
              end
            end

            def uri_path_for(folder)
              return "/root/children" if folder.root?

              "/items/#{folder.path}/children"
            end
          end
        end
      end
    end
  end
end

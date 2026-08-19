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
  module Adapters
    module Providers
      module Sharepoint
        module Queries
          module Internal
            class DriveItemQuery < Base
              def call(http:, drive_id:, item_id:, fields: [], expand: [])
                handle_response http.get("#{request_uri(drive_id:, item_id:)}#{query_string(fields:, expand:)}")
              end

              private

              def query_string(fields:, expand:)
                params = []
                params << "$select=#{fields.join(',')}" if fields.any?
                params << "$expand=#{expand.join(',')}" if expand.any?

                return "" if params.empty?

                "?#{params.join('&')}"
              end

              def handle_response(response)
                error = Results::Error.new(payload: response, source: self.class)

                case response
                in { status: 200..299 }
                  Success(response.json(symbolize_keys: true))
                in { status: 404 }
                  Failure(error.with(code: :not_found))
                in { status: 403 }
                  Failure(error.with(code: :forbidden))
                in { status: 401 }
                  Failure(error.with(code: :unauthorized))
                else
                  Failure(error.with(code: :error))
                end
              end

              def request_uri(drive_id:, item_id:)
                return UrlBuilder.url(base_uri, "/v1.0/drives", drive_id, "root") if item_id.root?

                UrlBuilder.url(base_uri, "/v1.0/drives", drive_id, "items", item_id)
              end
            end
          end
        end
      end
    end
  end
end

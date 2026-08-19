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
      module Nextcloud
        module Queries
          class UserQuery < Base
            def self.call(storage:, auth_strategy:)
              new(storage).call(auth_strategy:)
            end

            def call(auth_strategy:)
              Authentication[auth_strategy].call(storage: @storage, http_options: ocs_api_request_headers) do |http|
                handle_response(http.get(UrlBuilder.url(@storage.uri, "/ocs/v1.php/cloud/user")))
              end
            end

            private

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)
              case response
              in { status: 200..299 }
                handle_success_response(response)
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              else
                Failure(error.with(code: :error))
              end
            end

            def handle_success_response(response)
              error = Results::Error.new(source: self.class, payload: response)
              xml = Nokogiri::XML(response.body.to_s)
              statuscode = xml.xpath("/ocs/meta/statuscode").text

              case statuscode
              when "100"
                Success({ id: xml.xpath("/ocs/data/id").text })
              else
                Failure(error.with(code: :error))
              end
            end
          end
        end
      end
    end
  end
end

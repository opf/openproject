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
          class GroupUsersQuery < Base
            include TaggedLogging

            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                Authentication[auth_strategy].call(storage: @storage, http_options: ocs_api_request_headers) do |http|
                  url = UrlBuilder.url(@storage.uri, "ocs/v1.php/cloud/groups", input_data.group)
                  info "Requesting user list for group #{input_data.group} via url #{url} "

                  handle_response(http.get(url))
                end
              end
            end

            private

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                handle_success_response(response, error)
              in { status: 405 }
                Failure(error.with(code: :not_allowed))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 409 }
                Failure(error.with(code: :conflict))
              else
                Failure(error.with(code: :error))
              end
            end

            def handle_success_response(response, error)
              xml = Nokogiri::XML(response.body.to_s)
              status_code = xml.xpath("/ocs/meta/statuscode").text

              case status_code
              when "100"
                group_users = xml.xpath("/ocs/data/users/element").map(&:text)
                info "#{group_users.size} users found"
                Success(group_users)
              when "404"
                Failure(error.with(code: :group_does_not_exist))
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

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
        module Commands
          class RemoveUserFromGroupCommand < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                Authentication[auth_strategy].call(storage: @storage, http_options: ocs_api_request_headers) do |http|
                  url = UrlBuilder.url(@storage.uri, "ocs/v1.php/cloud/users", input_data.user, "groups")
                  url << "?groupid=#{CGI.escapeURIComponent(input_data.group)}"

                  info "Removing #{input_data.user} from #{input_data.group} through #{url}"
                  handle_response(http.delete(url))
                end
              end
            end

            private

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                handle_success_response(response.xml, error)
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

            # rubocop:disable Metrics/AbcSize
            def handle_success_response(response, error)
              status_code = response.xpath("/ocs/meta/statuscode").text
              case status_code
              when "100"
                info "User has been removed from group"
                Success()
              when "101"
                Failure(error.with(code: :no_group_specified))
              when "102"
                Failure(error.with(code: :group_does_not_exist))
              when "103"
                Failure(error.with(code: :user_does_not_exist))
              when "104"
                Failure(error.with(code: :insufficient_privileges))
              when "105"
                Failure(error.with(code: :failed_to_remove))
              else
                Failure(error.with(code: :error))
              end
            end
            # rubocop:enable Metrics/AbcSize
          end
        end
      end
    end
  end
end

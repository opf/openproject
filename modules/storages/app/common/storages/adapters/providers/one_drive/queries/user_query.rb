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
      module OneDrive
        module Queries
          class UserQuery < Base
            def self.call(storage:, auth_strategy:)
              new(storage).call(auth_strategy:)
            end

            def call(auth_strategy:)
              Authentication[auth_strategy].call(storage: @storage) do |http|
                handle_response http.get(UrlBuilder.url(@storage.uri, "/v1.0/me"))
              end
            end

            private

            def handle_response(response)
              error = Results::Error.new(payload: response, source: self.class)

              case response
              in { status: 200..299 }
                # FIXME: Make this into a Result::RemoteUserId - 2025-03-18 @mereghost
                Success(id: response.json["id"])
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 403 }
                Failure(error.with(code: :forbidden))
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

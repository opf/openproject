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
        module Commands
          class RenameFileCommand < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                info "Renaming file: #{input_data.inspect}"
                Authentication[auth_strategy].call(storage: @storage) do |http|
                  handle_response(
                    http.patch(UrlBuilder.url(base_uri, "items", input_data.location),
                               json: { name: input_data.new_name })
                  )
                end
              end
            end

            private

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 200..299 }
                StorageFileTransformer.new.transform(response.json(symbolize_keys: true))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 403 }
                Failure(error.with(code: :forbidden))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 409 }
                Failure(error.with(code: :conflict))
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

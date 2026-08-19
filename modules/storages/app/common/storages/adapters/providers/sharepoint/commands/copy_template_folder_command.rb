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
        module Commands
          class CopyTemplateFolderCommand < Base
            def initialize(storage)
              super
              @data = Results::CopyTemplateFolder.new(id: nil, polling_url: nil, requires_polling: true)
            end

            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                info "Requesting Copy of folder #{input_data.source} to #{input_data.destination}"
                Authentication[auth_strategy].call(storage: @storage) do |httpx|
                  split_identifier(input_data.source) => { drive_id: source_drive_id, location: source_item_id }
                  handle_response(
                    httpx.post(
                      UrlBuilder.url(base_uri,
                                     "/v1.0/drives",
                                     source_drive_id,
                                     "/items",
                                     source_item_id,
                                     "/copy") + query,
                      json: {
                        name: input_data.destination
                      }
                    )
                  )
                end
              end
            end

            private

            def handle_response(response)
              error = Results::Error.new(source: self.class, payload: response)

              case response
              in { status: 202 }
                Success(@data.with(polling_url: response.headers[:location]))
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

            def query = "?@microsoft.graph.conflictBehavior=fail"
          end
        end
      end
    end
  end
end

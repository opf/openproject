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
          class CreateFolderCommand < Base
            def call(auth_strategy:, input_data:)
              with_tagged_logger do
                info "Creating folder with args: #{input_data.to_h} | #{auth_strategy.value_or({}).to_h}"
                Authentication[auth_strategy].call(storage: @storage) do |http|
                  handle_response http.post(url_for(input_data.parent_location), json: payload(input_data.folder_name))
                end
              end
            end

            private

            def url_for(parent_location)
              if parent_location.root?
                UrlBuilder.url(base_uri, "/root/children")
              else
                UrlBuilder.url(base_uri, "/items", parent_location.path, "/children")
              end
            end

            def handle_response(response)
              error = Results::Error.new(payload: response, source: self.class)

              case response
              in { status: 200..299 }
                info "Folder successfully created."
                StorageFileTransformer.new.transform(response.json(symbolize_keys: true))
              in { status: 404 }
                Failure(error.with(code: :not_found))
              in { status: 401 }
                Failure(error.with(code: :unauthorized))
              in { status: 409 }
                Failure(error.with(code: :conflict))
              else
                Failure(error.with(code: :error))
              end
            end

            def payload(folder_name)
              { name: folder_name, folder: {}, "@microsoft.graph.conflictBehavior" => "fail" }
            end
          end
        end
      end
    end
  end
end

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Services
          class CreateManagedListService < ::Storages::BaseService
            # @param storage [Storages::SharepointStorage]
            def initialize(storage)
              super()
              @storage = storage
            end

            def call(name = "OpenProject")
              with_tagged_logger do
                info "Preparing to create the OpenProject Document Library on #{storage.host}"

                create_list_input = ProviderInput::CreateList.build(
                  name:, description: I18n.t("storages.provider_types.sharepoint.drive_description")
                ).value_or { return add_validation_error(it) }

                info "Requesting creation of the Document Library"
                list = Commands::CreateListCommand.call(storage:, auth_strategy:, input_data: create_list_input)
                                                  .value_or { return handle_failure(create_list_input, it) }

                @result.result = list
              end

              @result
            end

            private

            attr_reader :storage

            def auth_strategy = Registry["sharepoint.authentication.userless"].call

            def fetch_drive_info(name)
              error "Retrieving drive_id for the #{name} document library as it already exists"
              files_input = Input::Files.build(folder: "/").value_or { return add_validation_error(it) }

              Queries::FilesQuery.call(input_data: files_input, storage:, auth_strategy:).bind do |files_collection|
                @result.result = files_collection.files.find { it.name == name }
              end

              @result
            end

            def handle_failure(input_data, error)
              return fetch_drive_info(input_data.name) if error.code == :conflict

              error "Something went wrong: #{error.inspect}"
              add_error(:base, error)
            end
          end
        end
      end
    end
  end
end

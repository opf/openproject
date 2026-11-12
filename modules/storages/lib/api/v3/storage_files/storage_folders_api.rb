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

module API
  module V3
    module StorageFiles
      class StorageFoldersAPI < ::API::OpenProjectAPI
        using ::Storages::Peripherals::ServiceResultRefinements

        helpers ::Storages::Peripherals::StorageErrorHelper

        resources :folders do
          params do
            requires :name, type: String, desc: "Folder name"
            requires :parent_id, type: String, desc: "Id of the parent folder"
          end

          post do
            ::Storages::CreateFolderService.call(
              storage: @storage,
              user: current_user,
              folder_name: params["name"],
              parent_id: params["parent_id"]
            ).match(
              on_success: ->(storage_folder) {
                API::V3::StorageFiles::StorageFileRepresenter.new(storage_folder, @storage, current_user:)
              },
              on_failure: ->(error) { raise_service_result_error(error) }
            )
          end
        end
      end
    end
  end
end

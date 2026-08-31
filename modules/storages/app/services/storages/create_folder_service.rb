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
  class CreateFolderService < BaseService
    using Peripherals::ServiceResultRefinements

    def self.call(storage:, user:, folder_name:, parent_id:)
      new(storage).call(user:, folder_name:, parent_id:)
    end

    def initialize(storage)
      super()
      @storage = storage
    end

    def call(user:, folder_name:, parent_id:)
      error = parent_path(parent_id, user).bind do |parent_location|
        input_data = Adapters::Input::CreateFolder.build(folder_name:, parent_location:).value_or { return add_validation_error(it) }
        Adapters::Registry["#{@storage}.commands.create_folder"]
          .call(storage: @storage,
                auth_strategy: Adapters::Registry["#{@storage}.authentication.user_bound"].call(user, @storage),
                input_data:).bind do |created_folder|
          @result.result = created_folder
          return @result
        end
      end

      add_error(:base, error.failure)
    end

    private

    def parent_path(parent_id, user)
      case @storage.short_provider_type
      when "nextcloud"
        location_from_file_info(parent_id, user)
      when "onedrive", "sharepoint"
        Success(parent_id)
      else
        raise "Unknown Storage Type"
      end
    end

    def location_from_file_info(parent_id, user)
      StorageFileService.call(storage: @storage, user:, file_id: parent_id)
                        .to_monad.fmap { URI.decode_uri_component(it.location) }
    end
  end
end

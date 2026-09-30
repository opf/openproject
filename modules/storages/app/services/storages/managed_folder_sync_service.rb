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
  class ManagedFolderSyncService < BaseService
    using Peripherals::ServiceResultRefinements

    class << self
      def call(storage)
        new(storage).call
      end
    end

    def initialize(storage)
      super()
      @storage = storage
    end

    def call
      with_tagged_logger([self.class.name, "storage-#{@storage.id}"]) do
        info "Starting AMPF Sync for Storage #{@storage.id}"
        prepare_remote_folders
        apply_permissions_to_folders
        epilogue
      end
    end

    private

    def epilogue
      info "Synchronization process for Storage #{@storage.id} has ended. #{@result.errors.count} errors found."
      @result
    end

    def prepare_remote_folders
      folder_create_service.call(storage: @storage).tap do |subresult|
        @result.merge!(subresult)
      end
    end

    def apply_permissions_to_folders
      folder_permissions_service.call(storage: @storage).tap do |subresult|
        @result.merge!(subresult)
      end
    end

    def folder_create_service
      Adapters::Registry.resolve("#{@storage}.services.upkeep_managed_folders")
    end

    def folder_permissions_service
      Adapters::Registry.resolve("#{@storage}.services.upkeep_managed_folder_permissions")
    end
  end
end

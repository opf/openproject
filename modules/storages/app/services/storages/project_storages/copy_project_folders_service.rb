# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  module ProjectStorages
    class CopyProjectFoldersService
      # We might need the User too
      def self.call(source_id:, target_id:)
        new(source_id, target_id).call
      end

      def initialize(source_id, target_id)
        @source = get_project_storage(source_id)
        @target = get_project_storage(target_id)
      end

      def call
        return ServiceResult.success if @source.project_folder_inactive?
        return update_target(@source.project_folder_id) if @source.project_folder_manual?

        copy_result = copy_project_folder.on_failure { |failed_result| return failed_result }.result

        update_target(copy_result[:id]) if copy_result[:id]

        ServiceResult.failure(result: copy_result[:url], errors: :polling_required)
      end

      private

      def copy_project_folder
        Peripherals::Registry
          .resolve("#{@source.storage.short_provider_type}.commands.copy_template_folder")
          .call(storage: @source.storage,
                source_path: @source.project_folder_location,
                destination_path: @target.managed_project_folder_path)
      end

      def update_target(project_folder_id)
        ProjectStorages::UpdateService
          .new(user: User.system, model: @target)
          .call({ project_folder_id:, project_folder_mode: @source.project_folder_mode })
      end

      def get_project_storage(id)
        ProjectStorage.includes(:project, :storage).find(id)
      end
    end
  end
end

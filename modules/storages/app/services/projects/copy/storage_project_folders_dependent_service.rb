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

module Projects::Copy
  class StorageProjectFoldersDependentService < Dependency
    using Storages::Peripherals::ServiceResultRefinements

    def self.human_name
      I18n.t(:label_project_storage_project_folder)
    end

    def source_count
      # we copy the same amount of project folders as storages
      source.storages.count
    end

    protected

    def copy_dependency(*)
      return unless state.copied_project_storages

      state.copied_project_storages.each do |copied_project_storage|
        source = copied_project_storage[:source]
        target = copied_project_storage[:target]
        if source.project_folder_automatic?
          copy_project_folder(source, target).on_success do |copy_result|
            target.update!(project_folder_id: copy_result.result[:id], project_folder_mode: 'automatic')
          end
        elsif source.project_folder_manual?
          target.update!(project_folder_id: source.project_folder_id, project_folder_mode: 'manual')
        end
      end
    end

    private

    def copy_project_folder(source_project_storage, destination_project_storage)
      source_folder_name = source_project_storage.project_folder_location
      destination_folder_name = destination_project_storage.managed_project_folder_path

      Storages::Peripherals::Registry
        .resolve("#{source_project_storage.storage.short_provider_type}.commands.copy_template_folder")
        .call(
          storage: source_project_storage.storage,
          source_path: source_folder_name,
          destination_path: destination_folder_name
        ).on_failure { |r| add_error!(source_folder_name, r.to_active_model_errors) }
    end
  end
end

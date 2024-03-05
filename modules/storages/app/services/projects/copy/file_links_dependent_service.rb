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
  class FileLinksDependentService < Dependency
    def self.human_name
      I18n.t(:'projects.copy.work_package_file_links')
    end

    def source_count
      source.work_packages.joins(:file_links).count('file_links.id')
    end

    protected

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/PerceivedComplexity
    def copy_dependency(*)
      # If no work packages were copied, we cannot copy their file_links
      return unless state.work_package_id_lookup

      source_wp_ids = state.work_package_id_lookup.keys
      Storages::FileLink
        .where(container_id: source_wp_ids, container_type: "WorkPackage")
        .group_by(&:storage_id)
        .select { |_storage_id, source_file_links| source_file_links.any? }
        .each do |(storage_id, source_file_links)|
        tmp = state
                .copied_project_storages
                .find { |item| item["source"].storage_id == storage_id }
        source_project_storage = tmp['source']
        target_project_storage = tmp['target']
        storage = source_project_storage.storage

        if source_project_storage.project_folder_mode == 'automatic'
          files_info_query_result = files_info_query(storage:,
                                                     file_ids: source_file_links.map(&:origin_id))
          folder_files_file_ids_deep_query_result = folder_files_file_ids_deep_query(
            storage:,
            location: target_project_storage.managed_project_folder_path
          )
          source_file_links.each do |old_file_link|
            attributes = {
              storage_id: old_file_link.storage_id,
              creator_id: User.current.id,
              container_id: state.work_package_id_lookup[old_file_link.container_id.to_s],
              container_type: 'WorkPackage',
              origin_name: old_file_link.origin_name,
              origin_mime_type: old_file_link.origin_mime_type
            }

            original_file_location = files_info_query_result
                                       .find { |i| i.id.to_i == old_file_link.origin_id.to_i }
                                       .location

            attributes['origin_id'] =
              if source_project_storage.file_inside_project_folder?(original_file_location)
                new_file_location = original_file_location.gsub(
                  source_project_storage.project_folder_path_escaped,
                  target_project_storage.project_folder_path_escaped
                )
                new_file_location = CGI.unescape(new_file_location[1..])
                folder_files_file_ids_deep_query_result[new_file_location].id
              else
                old_file_link.origin_id
              end
            Storages::FileLinks::CreateService.new(user: User.current).call(attributes)
          end
        else
          source_file_links.each do |old_file_link|
            attributes = {
              storage_id: old_file_link.storage_id,
              creator_id: User.current.id,
              container_id: state.work_package_id_lookup[old_file_link.container_id.to_s],
              container_type: 'WorkPackage',
              origin_name: old_file_link.origin_name,
              origin_mime_type: old_file_link.origin_mime_type,
              origin_id: old_file_link.origin_id
            }
            Storages::FileLinks::CreateService.new(user: User.current).call(attributes)
          end
        end
      end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity

    def files_info_query(storage:, file_ids:)
      Storages::Peripherals::Registry
        .resolve("#{storage.short_provider_type}.queries.files_info")
        .call(storage:, user: User.current, file_ids:)
        .on_failure { |r| add_error!("files_info_query", r.to_active_model_errors) }
        .result
    end

    def folder_files_file_ids_deep_query(storage:, location:)
      Storages::Peripherals::Registry
        .resolve("#{storage.short_provider_type}.queries.folder_files_file_ids_deep_query")
        .call(storage:, folder: Storages::Peripherals::ParentFolder.new(location))
        .on_failure { |r| add_error!("folder_files_file_ids_deep_query", r.to_active_model_errors) }
        .result
    end
  end
end

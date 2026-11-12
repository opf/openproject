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
  module FileLinks
    class CopyFileLinksService < BaseService
      include OpenProject::LocaleHelper

      def self.call(source:, target:, user:, work_packages_map:)
        new(source:, target:, user:, work_packages_map:).call
      end

      def initialize(source:, target:, user:, work_packages_map:)
        super()
        @source = source
        @target = target
        @user = user
        @work_packages_map = work_packages_map.to_h { |key, value| [key.to_i, value.to_i] }
      end

      def call
        with_tagged_logger([self.class, @source.id, @target.id]) do
          source_file_links = FileLink.includes(:creator)
                                      .where(storage: @source.storage,
                                             container_id: @work_packages_map.keys,
                                             container_type: "WorkPackage")

          info "Found #{source_file_links.count} source file links"
          with_locale_for(@user) do
            info "Creating file links..."
            copy_file_links(source_file_links)
          end
        end
        info "File links creation finished"
        @result
      end

      private

      def copy_file_links(source_file_links)
        if @source.project_folder_automatic?
          create_file_links_when_folder_is_managed(source_file_links).or do |error|
            log_adapter_error(error)
            @result.success = false
          end
        else
          create_file_links_when_folder_is_unmanaged(source_file_links)
        end
      end

      def create_file_links_when_folder_is_managed(source_file_links)
        info "Getting information about the source file links"
        query_source_files_info(source_file_links).bind do |source_files_info|
          info "Getting information about the copied target files"

          query_target_project_folder_files_map.bind do |target_project_folder_files_map|
            target_project_folder_files_map.transform_keys! { |key| key.starts_with?("/") ? key : "/#{key}" }
            source_files_info.each do |info|
              potential_file_location_in_target_folder =
                info.clean_location&.gsub(@source.managed_project_folder_path,
                                          @target.managed_project_folder_path)
              storage_file_id =
                potential_file_location_in_target_folder.present? &&
                target_project_folder_files_map[potential_file_location_in_target_folder]
              source_link = source_file_links.find { |link| link.origin_id == info.id }
              if storage_file_id.present?
                create_file_link(source_link, storage_file_id.id)
              else
                create_file_link(source_link, source_link.origin_id)
              end
            end
            Success()
          end
        end
      end

      def create_file_link(source_link, origin_id)
        attributes = source_link.dup.attributes
        attributes.merge!(
          "storage_id" => @target.storage_id,
          "creator_id" => @user.id,
          "container_id" => @work_packages_map[source_link.container_id],
          "origin_id" => origin_id
        )

        CreateService.new(user: @user, contract_class: CopyContract).call(attributes)
      end

      def auth_strategy
        Adapters::Registry.resolve("#{@source.storage}.authentication.userless").call
      end

      def query_source_files_info(source_file_links)
        Adapters::Input::FilesInfo.build(file_ids: source_file_links.pluck(:origin_id)).bind do |input_data|
          Adapters::Registry.resolve("#{@source.storage}.queries.files_info")
                            .call(storage: @source.storage, auth_strategy:, input_data:)
        end
      end

      def query_target_project_folder_files_map
        Adapters::Input::FilePathToIdMap.build(folder: @target.project_folder_location).bind do |input_data|
          Adapters::Registry.resolve("#{@target.storage}.queries.file_path_to_id_map")
            .call(storage: @target.storage, auth_strategy:, input_data:)
        end
      end

      def create_file_links_when_folder_is_unmanaged(source_file_links)
        source_file_links.find_each do |source_file_link|
          create_file_link(source_file_link, source_file_link.origin_id)
        end
      end
    end
  end
end

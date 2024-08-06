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
  module FileLinks
    class CopyFileLinksService
      include OpenProject::LocaleHelper

      def self.call(source:, target:, user:, work_packages_map:)
        new(source:, target:, user:, work_packages_map:).call
      end

      def initialize(source:, target:, user:, work_packages_map:)
        @source = source
        @target = target
        @user = user
        @work_packages_map = work_packages_map.to_h { |key, value| [key.to_i, value.to_i] }
      end

      def call
        source_file_links = FileLink
                              .includes(:creator)
                              .where(storage: @source.storage,
                                     container_id: @work_packages_map.keys,
                                     container_type: "WorkPackage")

        with_locale_for(@user) do
          if @source.project_folder_automatic?
            create_managed_file_links(source_file_links)
          else
            create_unmanaged_file_links(source_file_links)
          end
        end
      end

      private

      # rubocop:disable Metrics/AbcSize
      def create_managed_file_links(source_file_links)
        source_info = source_files_info(source_file_links).on_failure do |failed|
          log_errors(failed)
          return failed
        end

        target_map = target_files_map.on_failure do |failed|
          log_errors(failed)
          return failed
        end

        location_map = build_location_map(source_info.result, target_map.result)

        source_file_links.find_each do |source_link|
          next unless location_map.has_key?(source_link.origin_id)

          attributes = source_link.dup.attributes
          attributes.merge!(
            "creator_id" => @user.id,
            "container_id" => @work_packages_map[source_link.container_id],
            "origin_id" => location_map[source_link.origin_id]
          )

          CreateService.new(user: @user, contract_class: CopyContract)
                       .call(attributes).on_failure { |failed| log_errors(failed) }
        end
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize
      def build_location_map(source_files, target_location_map)
        # We need this due to inconsistencies of how we represent the File Path
        target_location_map.transform_keys! { |key| key.starts_with?("/") ? key : "/#{key}" }

        # Since right now we can't make the relevant call as a remote admin we need to filter out 403 responses
        source_location_map = source_files.filter { |info| info.status_code.to_i == 200 }.to_h do |info|
          [info.id.to_s, info.clean_location]
        end

        source_location_map.each_with_object({}) do |(id, location), output|
          target = location.gsub(@source.managed_project_folder_path, @target.managed_project_folder_path)

          output[id] = target_location_map[target]&.id || id
        end
      end
      # rubocop:enable Metrics/AbcSize

      def auth_strategy
        Peripherals::Registry.resolve("#{@source.storage.short_provider_type}.authentication.userless").call
      end

      def source_files_info(source_file_links)
        Peripherals::Registry
          .resolve("#{@source.storage.short_provider_type}.queries.files_info")
          .call(storage: @source.storage, auth_strategy:, file_ids: source_file_links.pluck(:origin_id))
      end

      def target_files_map
        Peripherals::Registry
          .resolve("#{@source.storage.short_provider_type}.queries.file_path_to_id_map")
          .call(storage: @source.storage, auth_strategy:, folder: Peripherals::ParentFolder.new(@target.project_folder_location))
      end

      def create_unmanaged_file_links(source_file_links)
        source_file_links.find_each do |source_file_link|
          attributes = source_file_link.dup.attributes
          attributes["creator_id"] = @user.id
          attributes["container_id"] = @work_packages_map[source_file_link.container_id]

          FileLinks::CreateService.new(user: @user, contract_class: CopyContract)
                                  .call(attributes).on_failure { |failed| log_errors(failed) }
        end
      end

      def log_errors(failure)
        OpenProject.logger.error failure.inspect
        OpenProject.logger.error failure.errors.inspect
      end
    end
  end
end

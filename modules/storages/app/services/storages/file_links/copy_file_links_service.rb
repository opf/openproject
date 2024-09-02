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
      include TaggedLogging
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
        with_tagged_logger([self.class, @source.id, @target.id]) do
          source_file_links = FileLink.includes(:creator)
                                      .where(storage: @source.storage,
                                             container_id: @work_packages_map.keys,
                                             container_type: "WorkPackage")

          info "Found #{source_file_links.count} source file links"
          with_locale_for(@user) do
            info "Creating file links..."
            if @source.project_folder_automatic?
              create_managed_file_links(source_file_links)
            else
              create_unmanaged_file_links(source_file_links)
            end
          end
        end
        info "File link creation finished"
      end

      private

      # rubocop:disable Metrics/AbcSize
      def create_managed_file_links(source_file_links)
        info "Getting information about the source file links"
        source_info = source_files_info(source_file_links).on_failure do |failed|
          log_storage_error(failed.errors)
          return failed
        end

        info "Getting information about the copied target files"
        target_map = target_files_map.on_failure do |failed|
          log_storage_error(failed.errors)
          return failed
        end

        info "Building equivalency map..."
        location_map = build_location_map(source_info.result, target_map.result)

        info "Creating file links based on the location map #{location_map}"
        source_file_links.find_each do |source_link|
          next if location_map[source_link.origin_id].blank?

          attributes = source_link.dup.attributes
          attributes.merge!(
            "storage_id" => @target.storage_id,
            "creator_id" => @user.id,
            "container_id" => @work_packages_map[source_link.container_id],
            "origin_id" => location_map[source_link.origin_id]
          )

          CreateService.new(user: @user, contract_class: CopyContract)
                       .call(attributes).on_failure { |failed| log_errors(failed) }
        end
      end
      # rubocop:enable Metrics/AbcSize

      def build_location_map(source_files, target_location_map)
        # We need this due to inconsistencies of how we represent the File Path
        target_location_map.transform_keys! { |key| key.starts_with?("/") ? key : "/#{key}" }

        source_location_map = source_files.to_h { |info| [info.id.to_s, info.clean_location] }

        source_location_map.each_with_object({}) do |(id, location), output|
          target = location.gsub(@source.managed_project_folder_path, @target.managed_project_folder_path)

          output[id] = target_location_map[target]&.id || id
        end
      end

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
          .resolve("#{@target.storage.short_provider_type}.queries.file_path_to_id_map")
          .call(storage: @target.storage, auth_strategy:, folder: Peripherals::ParentFolder.new(@target.project_folder_location))
      end

      def create_unmanaged_file_links(source_file_links)
        source_file_links.find_each do |source_file_link|
          attributes = source_file_link.dup.attributes
          attributes["storage_id"] = @target.storage_id
          attributes["creator_id"] = @user.id
          attributes["container_id"] = @work_packages_map[source_file_link.container_id]

          FileLinks::CreateService.new(user: @user, contract_class: CopyContract)
                                  .call(attributes).on_failure { |failed| log_errors(failed) }
        end
      end

      def log_errors(failure)
        error failure.inspect
        error failure.errors.inspect
      end
    end
  end
end

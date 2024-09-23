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
  module ProjectStorages
    class CopyProjectFoldersService < BaseService
      using Peripherals::ServiceResultRefinements

      def self.call(source:, target:)
        new.call(source, target)
      end

      def initialize
        super
        @data = Peripherals::StorageInteraction::ResultData::CopyTemplateFolder
                .new(id: nil, polling_url: nil, requires_polling: false)
      end

      # rubocop:disable Metrics/AbcSize
      def call(source, target)
        with_tagged_logger([self.class, source&.id, target&.id]) do
          return @result.map { @data } if non_managed_project_folder?(source)
          return @result.map { @data.with(id: source.project_folder_id) } if manually_managed_source?(source)

          info "Initiating copy of project folder #{source.managed_project_folder_path} to #{target.managed_project_folder_path}"
          copy_result = initiate_copy(source.storage, source.project_folder_location, target.managed_project_folder_path)
          @result.map { copy_result.result }
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def non_managed_project_folder?(source)
        if source.project_folder_inactive?
          info "#{source.storage.name} on #{source.project.name} is inactive. Skipping copy."
          true
        end
      end

      def manually_managed_source?(source)
        if source.project_folder_manual?
          info "#{source.storage.name} on #{source.project.name} is set to manual. Skipping copy."
          true
        end
      end

      def initiate_copy(storage, source_path, destination_path)
        Peripherals::Registry
          .resolve("#{storage.short_provider_type}.commands.copy_template_folder")
          .call(auth_strategy: auth_strategy(storage.short_provider_type),
                storage:,
                source_path:,
                destination_path:).on_failure do |failed|
          log_storage_error(failed.errors)
          add_error(:base, failed.errors, options: { destination_path:, source_path: }).fail!
        end
      end

      def auth_strategy(short_provider_type)
        Peripherals::Registry.resolve("#{short_provider_type}.authentication.userless").call
      end
    end
  end
end

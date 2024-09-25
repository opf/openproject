# frozen_string_literal:true

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
  module Peripherals
    class NextcloudConnectionValidator
      include Dry::Monads[:maybe]

      using ServiceResultRefinements

      def initialize(storage:)
        @storage = storage
      end

      def validate
        maybe_is_not_configured
          .or { has_base_configuration_error? }
          .or { has_ampf_configuration_error? }
          .value_or(ConnectionValidation.new(type: :healthy,
                                             error_code: :none,
                                             timestamp: Time.current,
                                             description: nil))
      end

      private

      def has_base_configuration_error?
        host_url_not_found
          .or { missing_dependencies }
          .or { version_mismatch }
          .or { with_unexpected_content }
          .or { capabilities_request_failed_with_unknown_error }
      end

      def has_ampf_configuration_error?
        return None() unless @storage.automatic_management_enabled?

        userless_access_denied
          .or { group_folder_not_found }
          .or { files_request_failed_with_unknown_error }
      end

      def capabilities
        @capabilities ||= Peripherals::Registry
                            .resolve("#{@storage}.queries.capabilities")
                            .call(storage: @storage, auth_strategy: noop)
      end

      def files
        @files ||= Peripherals::Registry
                     .resolve("#{@storage}.queries.files")
                     .call(storage: @storage, auth_strategy: userless, folder: ParentFolder.new(@storage.group_folder))
      end

      def maybe_is_not_configured
        return None() if @storage.configured?

        Some(ConnectionValidation.new(type: :none,
                                      error_code: :wrn_not_configured,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.not_configured")))
      end

      def host_url_not_found
        return None() if capabilities.result != :not_found

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_host_not_found,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.host_not_found")))
      end

      # rubocop:disable Metrics/AbcSize
      def missing_dependencies
        return None() if capabilities.failure?

        capabilities_result = capabilities.result

        if !capabilities_result.app_enabled? || (@storage.automatically_managed? && !capabilities_result.group_folder_enabled?)
          app_name = if capabilities_result.app_enabled?
                       I18n.t("storages.dependencies.nextcloud.group_folders_app")
                     else
                       I18n.t("storages.dependencies.nextcloud.integration_app")
                     end

          Some(
            ConnectionValidation.new(
              type: :error,
              error_code: :err_missing_dependencies,
              timestamp: Time.current,
              description: I18n.t("storages.health.connection_validation.missing_dependencies", dependency: app_name)
            )
          )
        else
          None()
        end
      end

      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize
      def version_mismatch
        return None() if capabilities.failure?

        config = YAML.load_file(path_to_config).deep_stringify_keys!
        min_app_version = SemanticVersion.parse(config.dig("dependencies", "integration_app", "min_version"))
        min_group_folder_version = SemanticVersion.parse(config.dig("dependencies", "group_folders_app", "min_version"))

        capabilities_result = capabilities.result

        if capabilities_result.app_version < min_app_version
          Some(
            ConnectionValidation.new(
              type: :error,
              error_code: :err_unexpected_version,
              timestamp: Time.current,
              description: I18n.t("storages.health.connection_validation.app_version_mismatch",
                                  found: capabilities_result.app_version.to_s,
                                  expected: min_app_version.to_s)
            )
          )
        elsif @storage.automatically_managed? && capabilities_result.group_folder_version < min_group_folder_version
          Some(
            ConnectionValidation.new(
              type: :error,
              error_code: :err_unexpected_version,
              timestamp: Time.current,
              description: I18n.t("storages.health.connection_validation.group_folder_version_mismatch",
                                  found: capabilities_result.group_folder_version.to_s,
                                  expected: min_group_folder_version.to_s)
            )
          )
        else
          None()
        end
      end

      # rubocop:enable Metrics/AbcSize

      def userless_access_denied
        return None() if files.result != :unauthorized

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_userless_access_denied,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.userless_access_denied")))
      end

      def group_folder_not_found
        return None() if files.result != :not_found

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_group_folder_not_found,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.group_folder_not_found")))
      end

      # rubocop:disable Metrics/AbcSize
      def with_unexpected_content
        return None() unless @storage.automatic_management_enabled?
        return None() if files.failure?

        expected_folder_ids = @storage.project_storages
                                      .where(project_folder_mode: "automatic")
                                      .map(&:project_folder_id)

        unexpected_files = files.result.files.reject { |file| expected_folder_ids.include?(file.id) }
        return None() if unexpected_files.empty?

        Some(
          ConnectionValidation.new(
            type: :warning,
            error_code: :wrn_unexpected_content,
            timestamp: Time.current,
            description: I18n.t("storages.health.connection_validation.unexpected_content.nextcloud")
          )
        )
      end

      # rubocop:enable Metrics/AbcSize

      def capabilities_request_failed_with_unknown_error
        return None() if capabilities.success?

        Rails.logger.error(
          "Connection validation failed with unknown error:\n\t" \
          "storage: ##{@storage.id} #{@storage.name}\n\t" \
          "request: Nextcloud capabilities\n\t" \
          "status: #{capabilities.result}\n\t" \
          "response: #{capabilities.error_payload}"
        )

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_unknown,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.unknown_error")))
      end

      def files_request_failed_with_unknown_error
        return None() if files.success?

        Rails.logger.error(
          "Connection validation failed with unknown error:\n\t" \
          "storage: ##{@storage.id} #{@storage.name}\n\t" \
          "request: Group folder content\n\t" \
          "status: #{files.result}\n\t" \
          "response: #{files.error_payload}"
        )

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_unknown,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.unknown_error")))
      end

      def noop = StorageInteraction::AuthenticationStrategies::Noop.strategy

      def userless = Peripherals::Registry.resolve("#{@storage.short_provider_type}.authentication.userless").call

      def path_to_config = Rails.root.join("modules/storages/config/nextcloud_dependencies.yml")
    end
  end
end

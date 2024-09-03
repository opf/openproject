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
          .or { host_url_not_found }
          .or { missing_dependencies }
          .or { version_mismatch }
          .or { request_failed_with_unknown_error }
          .value_or(ConnectionValidation.new(type: :healthy,
                                             error_code: :none,
                                             timestamp: Time.current,
                                             description: nil))
      end

      private

      def query
        @query ||= Peripherals::Registry
                     .resolve("#{@storage.short_provider_type}.queries.capabilities")
                     .call(storage: @storage, auth_strategy:)
      end

      def maybe_is_not_configured
        return None() if @storage.configured?

        Some(ConnectionValidation.new(type: :none,
                                      error_code: :wrn_not_configured,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.not_configured")))
      end

      def host_url_not_found
        return None() if query.result != :not_found

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_host_not_found,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.host_not_found")))
      end

      # rubocop:disable Metrics/AbcSize
      def missing_dependencies
        return None() if query.failure?

        capabilities = query.result

        if !capabilities.app_enabled? || (@storage.automatically_managed? && !capabilities.group_folder_enabled?)
          app_name = if capabilities.app_enabled?
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
        return None() if query.failure?

        config = YAML.load_file(path_to_config).deep_stringify_keys!
        min_app_version = SemanticVersion.parse(config.dig("dependencies", "integration_app", "min_version"))
        min_group_folder_version = SemanticVersion.parse(config.dig("dependencies", "group_folders_app", "min_version"))

        capabilities = query.result

        if capabilities.app_version < min_app_version
          Some(
            ConnectionValidation.new(
              type: :error,
              error_code: :err_unexpected_version,
              timestamp: Time.current,
              description: I18n.t("storages.health.connection_validation.app_version_mismatch",
                                  found: capabilities.app_version.to_s,
                                  expected: min_app_version.to_s)
            )
          )
        elsif @storage.automatically_managed? && capabilities.group_folder_version < min_group_folder_version
          Some(
            ConnectionValidation.new(
              type: :error,
              error_code: :err_unexpected_version,
              timestamp: Time.current,
              description: I18n.t("storages.health.connection_validation.group_folder_version_mismatch",
                                  found: capabilities.group_folder_version.to_s,
                                  expected: min_group_folder_version.to_s)
            )
          )
        else
          None()
        end
      end

      # rubocop:enable Metrics/AbcSize

      def request_failed_with_unknown_error
        return None() if query.success?

        Rails.logger.error("Connection validation failed with unknown error:\n\t" \
                           "storage: ##{@storage.id} #{@storage.name}\n\t" \
                           "status: #{query.result}\n\t" \
                           "response: #{query.error_payload}")

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_unknown,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.unknown_error")))
      end

      def auth_strategy = StorageInteraction::AuthenticationStrategies::Noop.strategy

      def path_to_config
        Rails.root.join("modules/storages/config/nextcloud_dependencies.yml")
      end
    end
  end
end

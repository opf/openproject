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
    class OneDriveConnectionValidator
      include Dry::Monads[:maybe]

      using ServiceResultRefinements

      def initialize(storage:)
        @storage = storage
      end

      def validate
        maybe_is_not_configured
          .or { tenant_id_wrong }
          .or { client_id_wrong }
          .or { client_secret_wrong }
          .or { drive_id_wrong }
          .or { request_failed_with_unknown_error }
          .or { drive_with_unexpected_content }
          .value_or(ConnectionValidation.new(type: :healthy,
                                             error_code: :none,
                                             timestamp: Time.current,
                                             description: nil))
      end

      private

      def query
        @query ||= Peripherals::Registry
                     .resolve("#{@storage.short_provider_type}.queries.files")
                     .call(storage: @storage, auth_strategy:, folder: root_folder)
      end

      def maybe_is_not_configured
        return None() if @storage.configured?

        Some(ConnectionValidation.new(type: :none,
                                      error_code: :wrn_not_configured,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.not_configured")))
      end

      # rubocop:disable Metrics/AbcSize
      def drive_id_wrong
        return None() if query.success?

        validation_for_invalid_drive = ConnectionValidation.new(
          type: :error,
          error_code: :err_drive_invalid,
          timestamp: Time.current,
          description: I18n.t("storages.health.connection_validation.drive_id_wrong")
        )

        error_code = query.result
        return Some(validation_for_invalid_drive) if error_code == :not_found

        payload = query.error_payload
        return None() unless error_code == :error && payload.present? && payload.dig(:error, :code) == "invalidRequest"

        malformed_drive_id_string = "provided drive id appears to be malformed" # invalidRequest
        return None() unless payload.dig(:error, :message).include?(malformed_drive_id_string)

        Some(validation_for_invalid_drive)
      end

      # rubocop:enable Metrics/AbcSize

      def tenant_id_wrong
        return None() if query.result != :unauthorized

        payload = JSON.parse(query.error_payload)
        return None() if payload["error"] != "invalid_request"

        tenant_id_string = "Tenant '#{@storage.tenant_id}' not found."
        return None() unless payload["error_description"].include?(tenant_id_string)

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_tenant_invalid,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.tenant_id_wrong")))
      end

      def client_id_wrong
        return None() if query.result != :unauthorized

        payload = JSON.parse(query.error_payload)
        return None() if payload["error"] != "unauthorized_client"

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_client_invalid,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.client_id_wrong")))
      end

      def client_secret_wrong
        return None() if query.result != :unauthorized

        payload = JSON.parse(query.error_payload)
        return None() if payload["error"] != "invalid_client"

        Some(ConnectionValidation.new(type: :error,
                                      error_code: :err_client_invalid,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.client_secret_wrong")))
      end

      # rubocop:disable Metrics/AbcSize
      def drive_with_unexpected_content
        return None() if query.failure?
        return None() unless @storage.automatic_management_enabled?

        expected_folder_ids = @storage.project_storages
                                      .where(project_folder_mode: "automatic")
                                      .map(&:project_folder_id)

        unexpected_files = query.result.files.reject { |file| expected_folder_ids.include?(file.id) }
        return None() if unexpected_files.empty?

        Some(ConnectionValidation.new(type: :warning,
                                      error_code: :wrn_unexpected_content,
                                      timestamp: Time.current,
                                      description: I18n.t("storages.health.connection_validation.unexpected_content")))
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

      def root_folder
        Peripherals::ParentFolder.new("/")
      end

      def auth_strategy
        Peripherals::Registry.resolve("#{@storage.short_provider_type}.authentication.userless")
                             .call
                             .with_cache(false)
      end
    end
  end
end

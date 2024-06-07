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
  module Admin
    class ConnectionValidationController < ApplicationController
      include OpTurbo::ComponentStream
      include Dry::Monads[:maybe]

      using Peripherals::ServiceResultRefinements

      layout "admin"

      before_action :require_admin

      model_object OneDriveStorage

      before_action :find_model_object, only: %i[validate_connection]

      # rubocop:disable Metrics/AbcSize
      def validate_connection
        @result = maybe_is_not_configured
                    .or { drive_id_wrong }
                    .or { tenant_id_wrong }
                    .or { client_id_wrong }
                    .or { client_secret_wrong }
                    .or { request_failed_with_unknown_error }
                    .or { drive_with_unexpected_content }
                    .value_or(ConnectionValidation.new(icon: "check-circle",
                                                       scheme: :success,
                                                       description: I18n.t("storages.connection_validation.success")))

        respond_to do |format|
          format.turbo_stream
        end
      end

      # rubocop:enable Metrics/AbcSize

      private

      def query
        @query ||= Peripherals::Registry
                     .resolve("#{@storage.short_provider_type}.queries.files")
                     .call(storage: @storage, auth_strategy:, folder: root_folder)
      end

      def maybe_is_not_configured
        return None() if @storage.configured?

        Some(ConnectionValidation.new(icon: :alert,
                                      scheme: :warning,
                                      description: I18n.t("storages.connection_validation.not_configured")))
      end

      def drive_id_wrong
        return None() if query.result != :not_found

        Some(ConnectionValidation.new(icon: :skip,
                                      scheme: :danger,
                                      description: I18n.t("storages.connection_validation.drive_id_wrong")))
      end

      def tenant_id_wrong
        return None() if query.result != :unauthorized

        payload = JSON.parse(query.error_payload)
        return None() if payload["error"] != "invalid_request"

        tenant_id_string = "Tenant '#{@storage.tenant_id}' not found."
        return None() unless payload["error_description"].include?(tenant_id_string)

        Some(ConnectionValidation.new(icon: :skip,
                                      scheme: :danger,
                                      description: I18n.t("storages.connection_validation.tenant_id_wrong")))
      end

      def client_id_wrong
        return None() if query.result != :unauthorized

        payload = JSON.parse(query.error_payload)
        return None() if payload["error"] != "unauthorized_client"

        Some(ConnectionValidation.new(icon: :skip,
                                      scheme: :danger,
                                      description: I18n.t("storages.connection_validation.client_id_wrong")))
      end

      def client_secret_wrong
        return None() if query.result != :unauthorized

        payload = JSON.parse(query.error_payload)
        return None() if payload["error"] != "invalid_client"

        Some(ConnectionValidation.new(icon: :skip,
                                      scheme: :danger,
                                      description: I18n.t("storages.connection_validation.client_secret_wrong")))
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

        Some(ConnectionValidation.new(icon: :alert,
                                      scheme: :warning,
                                      description: I18n.t("storages.connection_validation.unexpected_content")))
      end

      # rubocop:enable Metrics/AbcSize

      def request_failed_with_unknown_error
        return None() if query.success?

        Rails.logger.error("Connection validation failed with unknown error:\n\t" \
                           "status: #{query.result}\n\tresponse: #{query.error_payload}")

        Some(ConnectionValidation.new(icon: :skip,
                                      scheme: :danger,
                                      description: I18n.t("storages.connection_validation.unknown_error")))
      end

      def find_model_object(object_id = :storage_id)
        super
        @storage = @object
      end

      def root_folder
        Peripherals::ParentFolder.new("/")
      end

      def auth_strategy
        Peripherals::Registry.resolve("#{@storage.short_provider_type}.authentication.userless").call
      end
    end
  end
end

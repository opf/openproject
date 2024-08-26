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
  module Peripherals
    module StorageInteraction
      module OneDrive
        class FileInfoQuery
          FIELDS = %w[id name fileSystemInfo file folder size createdBy lastModifiedBy parentReference].freeze

          def self.call(storage:, auth_strategy:, file_id:)
            new(storage).call(auth_strategy:, file_id:)
          end

          def initialize(storage)
            @storage = storage
            @drive_item_query = Internal::DriveItemQuery.new(storage)
            @error_data = StorageErrorData.new(source: self.class)
          end

          def call(auth_strategy:, file_id:)
            validation = validate_input(file_id)
            return validation if validation.failure?

            requested_result = Authentication[auth_strategy].call(storage: @storage) do |http|
              @drive_item_query.call(http:, drive_item_id: file_id, fields: FIELDS)
            end

            requested_result.on_success { |sr| return ServiceResult.success(result: storage_file_info(sr.result)) }
            requested_result.on_failure do |sr|
              return sr unless sr.result == :not_found && auth_strategy.user.present?

              return admin_query(file_id)
            end
          end

          private

          def admin_query(file_id)
            admin_result = Authentication[userless_strategy].call(storage: @storage) do |http|
              @drive_item_query.call(http:, drive_item_id: file_id, fields: FIELDS)
            end

            admin_result.on_success do |admin_query|
              return ServiceResult.success(
                result: storage_file_info(admin_query.result, status: "forbidden", status_code: 403)
              )
            end
          end

          def validate_input(file_id)
            if file_id.nil?
              ServiceResult.failure(
                result: :error,
                errors: StorageError.new(code: :error,
                                         data: @error_data, log_message: "File ID can not be nil")
              )
            else
              ServiceResult.success
            end
          end

          def userless_strategy = Registry.resolve("one_drive.authentication.userless").call

          def storage_file_info(json, status: "ok", status_code: 200) # rubocop:disable Metrics/AbcSize
            StorageFileInfo.new(
              status:,
              status_code:,
              id: json[:id],
              name: json[:name],
              mime_type: Util.mime_type(json),
              size: json[:size],
              owner_name: json.dig(:createdBy, :user, :displayName),
              owner_id: json.dig(:createdBy, :user, :id),
              permissions: nil,
              location: UrlBuilder.path(Util.extract_location(json[:parentReference], json[:name])),
              last_modified_at: Time.zone.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
              created_at: Time.zone.parse(json.dig(:fileSystemInfo, :createdDateTime)),
              last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
              last_modified_by_id: json.dig(:lastModifiedBy, :user, :id)
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

          def self.call(storage:, user:, file_id:)
            new(storage).call(user:, file_id:)
          end

          def initialize(storage)
            @delegate = Internal::DriveItemQuery.new(storage)
          end

          def call(user:, file_id:)
            @delegate.call(user:, drive_item_id: file_id, fields: FIELDS).map(&storage_file_infos)
          end

          private

          def storage_file_infos
            ->(json) do
              StorageFileInfo.new(
                status: 'ok',
                status_code: 200,
                id: json[:id],
                name: json[:name],
                last_modified_at: DateTime.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
                created_at: DateTime.parse(json.dig(:fileSystemInfo, :createdDateTime)),
                mime_type: Util.mime_type(json),
                size: json[:size],
                owner_name: json.dig(:createdBy, :user, :displayName),
                owner_id: json.dig(:createdBy, :user, :id),
                trashed: false,
                last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
                last_modified_by_id: json.dig(:lastModifiedBy, :user, :id),
                permissions: nil,
                location: json.dig(:parentReference, :path)
              )
            end
          end
        end
      end
    end
  end
end

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
  module Adapters
    module Providers
      module OneDrive
        class StorageFileTransformer
          def transform(json)
            Results::StorageFile.build(
              id: json[:id],
              name: json[:name],
              size: json[:size],
              mime_type: mime_type(json),
              created_at: Time.zone.parse(json.dig(:fileSystemInfo, :createdDateTime)),
              last_modified_at: Time.zone.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
              created_by_name: json.dig(:createdBy, :user, :displayName),
              last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
              location: extract_location(json[:parentReference], json[:name]),
              permissions: %i[readable writeable]
            )
          end

          def bare_transform(id:, location:)
            Results::StorageFile.new(id:, name: location.split("/").last, location:,
                                     permissions: %i[readable writeable])
          end

          def parent_transform(id:, location:, name:)
            Results::StorageFile.new(id:, name:, location: extract_location(location),
                                     permissions: %i[readable writeable])
          end

          def transform_file_info(json)
            # Need to handle the errors
            Results::StorageFileInfo.build(
              status: json[:status],
              status_code: json[:status_code],
              id: json[:id],
              name: json[:name],
              mime_type: mime_type(json),
              size: json[:size],
              owner_name: json.dig(:createdBy, :user, :displayName),
              owner_id: json.dig(:createdBy, :user, :id),
              location: extract_location(json[:parentReference], json[:name]),
              last_modified_at: json.dig(:fileSystemInfo, :lastModifiedDateTime),
              created_at: json.dig(:fileSystemInfo, :createdDateTime),
              last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
              last_modified_by_id: json.dig(:lastModifiedBy, :user, :id)
            ).value_or(nil)
          end

          private

          def mime_type(json)
            json.dig(:file, :mimeType) || (json.key?(:folder) ? "application/x-op-directory" : nil)
          end

          def extract_location(parent_reference, file_name = "")
            location = parent_reference[:path].gsub(/.*root:/, "")

            appendix = file_name.blank? ? "" : "/#{file_name}"
            location.empty? ? "/#{file_name}" : "#{location}#{appendix}"
          end
        end
      end
    end
  end
end

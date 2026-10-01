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
      module Sharepoint
        class StorageFileTransformer
          attr_reader :host_uri

          def initialize(host_uri)
            @host_uri = host_uri
          end

          def transform(json)
            Results::StorageFile.build(
              id: compose_id(json),
              name: json[:name],
              size: json[:size],
              mime_type: mime_type(json),
              location: extract_location(json),
              created_at: Time.zone.parse(json.dig(:fileSystemInfo, :createdDateTime)),
              last_modified_at: Time.zone.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
              created_by_name: json.dig(:createdBy, :user, :displayName),
              last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
              permissions: %i[readable writeable]
            )
          end

          def parent_transform(json)
            Results::StorageFile.new(
              name: json.dig(:parentReference, :name),
              id: compose_parent_id(json[:parentReference]),
              location: extract_parent_location(json),
              permissions: %i[readable writeable]
            )
          end

          def bare_transform(json)
            Results::StorageFile.new(
              name: json[:name],
              id: compose_id(json),
              location: extract_location(json),
              permissions: %i[readable writeable]
            )
          end

          def transform_file_info(json)
            Results::StorageFileInfo.build(
              status: json[:status],
              status_code: json[:status_code],
              id: compose_id(json),
              name: json[:name],
              mime_type: mime_type(json),
              size: json[:size],
              owner_name: json.dig(:createdBy, :user, :displayName),
              owner_id: json.dig(:createdBy, :user, :id),
              location: extract_location(json),
              last_modified_at: json.dig(:fileSystemInfo, :lastModifiedDateTime),
              created_at: json.dig(:fileSystemInfo, :createdDateTime),
              last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
              last_modified_by_id: json.dig(:lastModifiedBy, :user, :id)
            ).value_or(nil)
          end

          def build_ancestor(name, location)
            Results::StorageFileAncestor.new(name:, location:)
          end

          private

          def mime_type(entry)
            return "application/x-op-directory" if entry.key? :folder

            entry.dig(:file, :mimeType)
          end

          def extract_location(json)
            # the host_uri always includes a trailing slash, so we re-add it.
            location = "/#{json[:webUrl].delete_prefix(host_uri)}"
            CGI.unescapeURIComponent(location)
          end

          def extract_parent_location(json)
            rindex = UrlBuilder.path(json[:name]).length * -1
            extract_location(json)[0...rindex]
          end

          def compose_id(json)
            "#{json.dig(:parentReference, :driveId)}#{SharepointStorage::IDENTIFIER_SEPARATOR}#{json[:id]}"
          end

          def compose_parent_id(parent)
            item_id = parent[:path].ends_with?("root:") ? nil : parent[:id]

            "#{parent[:driveId]}#{SharepointStorage::IDENTIFIER_SEPARATOR}#{item_id}"
          end
        end
      end
    end
  end
end

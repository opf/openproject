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
        module Util
          using ServiceResultRefinements

          class << self
            def mime_type(json)
              json.dig(:file, :mimeType) || (json.key?(:folder) ? "application/x-op-directory" : nil)
            end

            def storage_error(response:, code:, source:, log_message: nil)
              # Some errors, like timeouts, aren't json responses so we need to adapt
              payload = response.respond_to?(:json) ? response.json(symbolize_keys: true) : response.to_s
              data = StorageErrorData.new(source:, payload:)

              StorageError.new(code:, data:, log_message:)
            end

            def drive_base_uri(storage)
              URI.parse(UrlBuilder.url(storage.uri, "/v1.0/drives", storage.drive_id))
            end

            def json_content_type
              { headers: { "Content-Type" => "application/json" } }
            end

            def extract_location(parent_reference, file_name = "")
              location = parent_reference[:path].gsub(/.*root:/, "")

              appendix = file_name.blank? ? "" : "/#{file_name}"
              location.empty? ? "/#{file_name}" : "#{location}#{appendix}"
            end

            def storage_file_from_json(json)
              StorageFile.new(
                id: json[:id],
                name: json[:name],
                size: json[:size],
                mime_type: Util.mime_type(json),
                created_at: Time.zone.parse(json.dig(:fileSystemInfo, :createdDateTime)),
                last_modified_at: Time.zone.parse(json.dig(:fileSystemInfo, :lastModifiedDateTime)),
                created_by_name: json.dig(:createdBy, :user, :displayName),
                last_modified_by_name: json.dig(:lastModifiedBy, :user, :displayName),
                location: UrlBuilder.path(Util.extract_location(json[:parentReference], json[:name])),
                permissions: %i[readable writeable]
              )
            end
          end
        end
      end
    end
  end
end

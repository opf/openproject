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
  module Peripherals
    module StorageInteraction
      module OneDrive
        class CopyTemplateFolderCommand
          def self.call(storage:, source_path:, destination_path:)
            raise ArgumentError if source_path.blank? || destination_path.blank?

            new(storage).call(source_path, destination_path)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(source_path, destination_path)
            normalized_destination = normalize_path(destination_path)

            Util.using_admin_token(@storage) do |httpx|
              handle_response(
                httpx.post(copy_path_for(source_path), json: payload(normalized_destination))
              )
            end
          end

          private

          def handle_response(response)
            case response
            in { status: 202 }
              id = extract_id_from_url(response.headers[:location])

              ServiceResult.success(result: { id:, url: response.headers[:location] })
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized)
            in { status: 403 }
              ServiceResult.failure(result: :forbidden)
            in { status: 404 }
              ServiceResult.failure(result: :not_found, message: 'Template folder not found')
            in { status: 409 }
              ServiceResult.failure(result: :conflict, message: 'The copy would overwrite an already existing folder')
            else
              ServiceResult.failure(result: :error)
            end
          end

          def extract_id_from_url(url)
            extractor_regex = /.+\/items\/(?<item_id>\w+)\?/
            match_data = extractor_regex.match(url)

            match_data[:item_id] if match_data
          end

          def payload(destination_path)
            {
              name: destination_path
            }
          end

          def copy_path_for(path)
            "/v1.0/drives/#{@storage.drive_id}/items/#{path}/copy?@microsoft.graph.conflictBehavior=fail"
          end

          def normalize_path(path)
            path.gsub(/[\\<>+?:"|\/]/, '')
          end
        end
      end
    end
  end
end

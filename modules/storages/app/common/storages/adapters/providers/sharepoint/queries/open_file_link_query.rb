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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Queries
          class OpenFileLinkQuery < Base
            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do |http|
                split_identifier(input_data.file_id) => { drive_id:, location: item_id }

                if input_data.open_location
                  request_parent_id(http, drive_id, item_id).bind { request_web_url(http, drive_id, it) }
                else
                  request_web_url(http, drive_id, item_id)
                end
              end
            end

            private

            def drive_item_query
              @drive_item_query ||= Internal::DriveItemQuery.new(@storage)
            end

            def request_web_url(http, drive_id, item_id)
              drive_item_query.call(http:, drive_id:, item_id:, fields: %w[webUrl]).fmap { it[:webUrl] }
            end

            def request_parent_id(http, drive_id, item_id)
              drive_item_query.call(http:, drive_id:, item_id:, fields: %w[parentReference])
                              .fmap { Peripherals::ParentFolder.new(it.dig(:parentReference, :id) || "/") }
            end
          end
        end
      end
    end
  end
end

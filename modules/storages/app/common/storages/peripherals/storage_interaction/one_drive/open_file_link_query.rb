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
        class OpenFileLinkQuery
          using ::Storages::Peripherals::ServiceResultRefinements
          Auth = ::Storages::Peripherals::StorageInteraction::Authentication

          def self.call(storage:, auth_strategy:, file_id:, open_location: false)
            new(storage).call(auth_strategy:, file_id:, open_location:)
          end

          def initialize(storage)
            @storage = storage
            @delegate = Internal::DriveItemQuery.new(storage)
          end

          def call(auth_strategy:, file_id:, open_location: false)
            Auth[auth_strategy].call(storage: @storage) do |http|
              if open_location
                request_parent_id(http).call(file_id) >> request_web_url(http)
              else
                request_web_url(http).call(file_id)
              end
            end
          end

          private

          def request_web_url(http)
            ->(file_id) do
              @delegate.call(http:, drive_item_id: file_id, fields: %w[webUrl]).map(&web_url)
            end
          end

          def request_parent_id(http)
            ->(file_id) do
              @delegate.call(http:, drive_item_id: file_id, fields: %w[parentReference]).map(&parent_id)
            end
          end

          def web_url
            ->(json) do
              json[:webUrl]
            end
          end

          def parent_id
            ->(json) do
              json.dig(:parentReference, :id)
            end
          end
        end
      end
    end
  end
end

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
        class Base
          include TaggedLogging
          include Dry::Monads::Result(Results::Error)

          # @param storage [Storages::SharepointStorage]
          # @param auth_strategy [Result(Input::Strategy)]
          # @param input_data [Data]
          # @return [Success, Failure(Results::Error)]
          def self.call(storage:, auth_strategy:, input_data:)
            new(storage).call(auth_strategy:, input_data:)
          end

          # @param storage [Storages::SharepointStorage]
          def initialize(storage)
            @storage = storage
          end

          def base_uri = @storage.uri

          private

          def site_name
            host_uri.path&.split("/")&.last
          end

          def site_path
            UrlBuilder.path(host_uri.path)
          end

          def host_uri
            URI(@storage.host)
          end

          def split_identifier(location)
            drive_id, item_id = location.to_s.split(SharepointStorage::IDENTIFIER_SEPARATOR)
            { drive_id:, location: Peripherals::ParentFolder.new(item_id || "/") }
          end

          def request_uri = raise SubclassResponsibilityError

          # @param error [Results::Error]
          # @return [void]
          def log_storage_error(error, context = {})
            data = case error.payload
                   in { status: Integer }
                     { status: error.payload&.status, body: error.payload&.body.to_s }
                   else
                     error.payload.to_s
                   end

            error_message = context.merge({ error_code: error.code, data: })
            error error_message
          end
        end
      end
    end
  end
end

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
        class Base
          include TaggedLogging
          include Dry::Monads::Result(Results::Error)

          def self.call(storage:, auth_strategy:, input_data:)
            new(storage).call(auth_strategy:, input_data:)
          end

          def initialize(storage)
            @storage = storage
          end

          private

          # @param error [Results::Error]
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

          def base_uri
            URI.parse(UrlBuilder.url(@storage.uri, "/v1.0/drives", @storage.drive_id))
          end
        end
      end
    end
  end
end

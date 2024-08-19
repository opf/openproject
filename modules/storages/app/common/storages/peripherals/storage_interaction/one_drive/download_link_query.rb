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
        class DownloadLinkQuery
          def self.call(storage:, auth_strategy:, file_link:)
            new(storage).call(auth_strategy:, file_link:)
          end

          def initialize(storage)
            @storage = storage
          end

          def call(auth_strategy:, file_link:)
            if file_link.nil?
              return ServiceResult.failure(result: :error,
                                           errors: Util.storage_error(code: :error, response: nil, source: self.class,
                                                                      log_message: "File link can not be nil."))
            end

            Authentication[auth_strategy].call(storage: @storage) do |http|
              handle_errors http.get(url_for(file_link.origin_id))
            end
          end

          private

          def handle_errors(response)
            case response
            in { status: 300..399 }
              ServiceResult.success(result: response.headers["Location"])
            in { status: 404 }
              ServiceResult.failure(result: :not_found,
                                    errors: Util.storage_error(code: :not_found, response:, source: self.class,
                                                               log_message: "Outbound request destination not found!"))
            in { status: 403 }
              ServiceResult.failure(result: :forbidden,
                                    errors: Util.storage_error(code: :forbidden, response:, source: self.class,
                                                               log_message: "Outbound request forbidden!"))
            in { status: 401 }
              ServiceResult.failure(result: :unauthorized,
                                    errors: Util.storage_error(code: :unauthorized, response:, source: self.class,
                                                               log_message: "Outbound request not authorized!"))
            else
              ServiceResult.failure(result: :error,
                                    errors: Util.storage_error(code: :error, response:, source: self.class,
                                                               log_message: "Outbound request failed with unknown error!"))
            end
          end

          def url_for(file_id)
            UrlBuilder.url(Util.drive_base_uri(@storage), "items", file_id, "content")
          end
        end
      end
    end
  end
end

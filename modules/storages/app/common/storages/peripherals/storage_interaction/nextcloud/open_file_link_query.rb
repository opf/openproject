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
      module Nextcloud
        class OpenFileLinkQuery
          def self.call(storage:, auth_strategy:, file_id:, open_location: false)
            new(storage).call(auth_strategy:, file_id:, open_location:)
          end

          def initialize(storage)
            @storage = storage
          end

          # rubocop:disable Lint/UnusedMethodArgument
          def call(auth_strategy:, file_id:, open_location: false)
            location_flag = open_location ? 0 : 1
            url = UrlBuilder.url(@storage.uri, "index.php/f/#{file_id}") + "?openfile=#{location_flag}"
            ServiceResult.success(result: url)
          end

          # rubocop:enable Lint/UnusedMethodArgument
        end
      end
    end
  end
end

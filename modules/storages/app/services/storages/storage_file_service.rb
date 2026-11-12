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
  class StorageFileService < BaseService
    def self.call(storage:, user:, file_id:)
      new.call(storage:, user:, file_id:)
    end

    def call(user:, storage:, file_id:)
      auth_strategy = Adapters::Registry.resolve("#{storage}.authentication.user_bound").call(user, storage)

      info "Requesting file #{file_id} information on #{storage.name}"
      input_data = Adapters::Input::FileInfo.build(file_id:).value_or { return add_validation_error(it) }

      file_info = Adapters::Registry.resolve("#{storage}.queries.file_info").call(storage:, auth_strategy:, input_data:)
                                    .value_or { return add_error(:base, it, options: { file_id: }) }

      @result.result = file_info
      @result
    end
  end
end

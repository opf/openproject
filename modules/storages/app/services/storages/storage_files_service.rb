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
  class StorageFilesService < BaseService
    def self.call(storage:, user:, folder:)
      new.call(storage:, user:, folder:)
    end

    def call(user:, storage:, folder:)
      with_tagged_logger do
        auth_strategy = strategy(storage, user)

        info "Requesting all the files under folder #{folder} for #{storage.name}"

        input_data = Adapters::Input::Files.build(folder:).value_or { return add_validation_error(it) }

        files = Adapters::Registry
                  .resolve("#{storage}.queries.files").call(storage:, auth_strategy:, input_data:)
                  .value_or { return add_error(:base, it, options: { storage_name: storage.name, folder: }) }

        @result.result = files
        @result
      end
    end

    private

    def strategy(storage, user)
      Adapters::Registry.resolve("#{storage}.authentication.user_bound").call(user, storage)
    end
  end
end

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
  class UploadLinkService < BaseService
    def self.call(user:, storage:, upload_data:)
      new(storage).call(user:, upload_data:)
    end

    def initialize(storage)
      super()
      @storage = storage
    end

    def call(user:, upload_data:)
      with_tagged_logger do
        info "Validating upload information"
        input = validate_input(**upload_data).value_or { return @result }

        info "Upload data validated..."
        info "Requesting an upload link to #{@storage.name}"
        upload_link = request_upload_link(auth_strategy(user), input).on_failure { return @result }.result

        @result.result = upload_link
        @result
      end
    end

    private

    def request_upload_link(auth_strategy, upload_data)
      Peripherals::Registry.resolve("#{@storage}.queries.upload_link")
                           .call(storage: @storage, auth_strategy:, upload_data:)
                           .on_failure do |error|
        add_error(:base, error.errors, options: { storage_name: @storage.name, folder: upload_data.folder_id })
        log_storage_error(error.errors)
        @result.success = false
      end
    end

    def validate_input(...)
      Peripherals::StorageInteraction::Inputs::UploadData.build(...).alt_map do |failure|
        error failure.inspect
        @result.add_error(:base, :invalid, options: failure.to_h)
        @result.success = false
      end
    end

    def auth_strategy(user)
      Peripherals::Registry.resolve("#{@storage}.authentication.user_bound").call(user:)
    end
  end
end

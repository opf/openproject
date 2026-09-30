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
  class FileLinkSyncService < BaseService
    def initialize(user:)
      super()
      @user = user
    end

    def call(file_links)
      with_tagged_logger do
        info "Starting File Link remote synchronization"

        resulting_file_links = file_links.group_by(&:storage).flat_map do |storage, records|
          sync_storage_data(storage, records)
        end

        @result.result = resulting_file_links
        info "File Link Synchronization successful"
        @result
      end
    end

    private

    def sync_storage_data(storage, file_links)
      info "Retrieving file link information from #{storage.name}"

      input_data = Adapters::Input::FilesInfo.build(file_ids: file_links.map(&:origin_id))
                                             .value_or { return add_validation_error(it) }

      infos = Adapters::Registry.resolve("#{storage}.queries.files_info")
                                .call(storage:, auth_strategy: auth_strategy(storage), input_data:)

      infos.either(->(success) { set_file_link_status(file_links, success) }, ->(*) { set_error_status(file_links) })
    end

    def set_error_status(file_links)
      file_links.map do |file_link|
        file_link.origin_status = :error
        file_link
      end
    end

    def auth_strategy(storage)
      Adapters::Registry.resolve("#{storage}.authentication.user_bound").call(@user, storage)
    end

    def set_file_link_status(file_links, file_infos)
      info "Updating file link status..."
      indexed = file_infos.index_by(&:id)

      file_links.map do |file_link|
        file_info = indexed[file_link.origin_id]
        file_link.origin_status = case file_info.status_code
                                  when 200
                                    update_file_link(file_link, file_info)
                                    :view_allowed
                                  when 403
                                    :view_not_allowed
                                  when 404
                                    :not_found
                                  else
                                    :error
                                  end

        file_link
      end
    end

    def update_file_link(file_link, file_info)
      file_link.update!(
        origin_mime_type: file_info.mime_type,
        origin_created_by_name: file_info.owner_name,
        origin_last_modified_by_name: file_info.last_modified_by_name,
        origin_name: file_info.name,
        origin_created_at: file_info.created_at,
        origin_updated_at: file_info.last_modified_at
      )
    end
  end
end

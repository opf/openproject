#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Storages::Peripherals
  class StorageRequests
    def initialize(storage:)
      @storage = storage
      @oauth_client = storage.oauth_client
    end

    def download_link_query(user:)
      storage_queries(user)
        .download_link_query
        .map { |query| query.method(:query).to_proc }
    end

    def files_query(user:)
      storage_queries(user)
        .files_query
        .map { |query| query.method(:query).to_proc }
    end

    def file_query(user:)
      storage_queries(user)
        .file_query
        .map { |query| query.method(:query).to_proc }
    end

    def upload_link_query(user:)
      storage_queries(user)
        .upload_link_query
        .map { |query| query.method(:query).to_proc }
    end

    private

    def storage_queries(user)
      ::Storages::Peripherals::StorageInteraction::StorageQueries
        .new(
          uri: URI(@storage.host).normalize,
          provider_type: @storage.provider_type,
          user:,
          oauth_client: @oauth_client
        )
    end
  end
end

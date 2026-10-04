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
  module Adapters
    module Providers
      module Nextcloud
        module Queries
          class FilePathToIdMapQuery < Base
            def initialize(*)
              super
              @propfind_query = PropfindQuery.new(@storage)
            end

            def call(auth_strategy:, input_data:)
              origin_user_id(auth_strategy:).bind do |origin_user_id|
                Authentication[auth_strategy].call(storage: @storage, http_options: headers(input_data.depth)) do |http|
                  # nc:acl-list is only required to avoid https://community.openproject.org/wp/49628. See comment #4.
                  @propfind_query.call(http:,
                                       username: origin_user_id,
                                       path: input_data.folder.path,
                                       props: %w[oc:fileid nc:acl-list])
                                 .fmap do |obj|
                    obj.transform_values { |value| StorageFileId.new(id: value["fileid"]) }
                  end
                end
              end
            end

            private

            def headers(depth)
              { headers: { "Depth" => depth.to_s.downcase } }
            end
          end
        end
      end
    end
  end
end

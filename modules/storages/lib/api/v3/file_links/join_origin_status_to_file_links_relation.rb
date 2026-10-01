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

module API
  module V3
    module FileLinks
      class JoinOriginStatusToFileLinksRelation
        # @param [Hash] id_status_map A hash mapping file link IDs to their origin status
        # in the format { 137: "view_allowed", 142: "error" }
        def self.create(id_status_map)
          sanitized_sql = OpenProject::SqlSanitization.sanitize(
            origin_status_join(id_status_map.size), *id_status_map.flatten
          )

          ::Storages::FileLink.where(id: id_status_map.keys)
                              .order(:id)
                              .joins(sanitized_sql)
                              .select("file_links.*, origin_status.status AS origin_status")
        end

        def self.origin_status_join(value_count)
          placeholders = Array.new(value_count).map { "(?,?)" }.join(",")

          <<-SQL.squish
            LEFT JOIN (VALUES #{placeholders}) AS origin_status (id,status) ON origin_status.id = file_links.id
          SQL
        end
      end
    end
  end
end

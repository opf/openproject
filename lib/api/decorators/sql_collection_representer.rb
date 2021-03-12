#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module Decorators
    class SqlCollectionRepresenter
      class_attribute :embed_map

      class << self
        def joins(_select, scope)
          scope
        end

        def ctes(walker_result)
          {
            all_elements: walker_result.scope.to_sql,
            page_elements: "SELECT * FROM all_elements LIMIT #{walker_result.page_size} OFFSET #{walker_result.offset}"
          }
        end

        def select_sql(replace_map, _select, walker_result)
          sql = <<~SELECT
            json_build_object(
              '_type', 'Collection',
              'count', COUNT(*),
              'total', (SELECT COUNT(*) from all_elements),
              'perPage', #{walker_result.page_size},
              'offset', #{walker_result.offset + 1},
              '_embedded', json_build_object(
                'elements', json_agg(
                  %<elements>s
                )
              )
            )
          SELECT

          sql % replace_map.symbolize_keys
        end

        def to_sql(walker_result)
          ctes = walker_result.ctes.map do |key, sql|
            <<~SQL
              #{key} AS (
                #{sql}
              )
            SQL
          end

          <<~SQL
             WITH #{ctes.join(', ')}

             SELECT
              #{walker_result.selects} AS json
            FROM
              page_elements
          SQL
        end
      end
    end
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
    module Projects
      class ProjectSqlRepresenter
        include API::Decorators::Sql::Hal

        class << self
          def ctes(walker_result)
            {
              ancestors: ancestors_sql(walker_result)
            }
          end

          protected

          def ancestors_sql(walker_result)
            <<-SQL.squish
              SELECT id, json_agg(link) ancestors
              FROM
                (
                  SELECT
                    origin.id,
                    json_build_object('href', format('/api/v3/projects/%s', ancestors.id), 'title', ancestors.name) link
                  FROM projects origin
                  JOIN projects ancestors
                  ON ancestors.lft < origin.lft AND ancestors.rgt > origin.rgt
                  WHERE origin.id IN (#{walker_result.filter_scope.limit(walker_result.page_size).offset((walker_result.offset - 1) * walker_result.page_size).select(:id).to_sql})
                  ORDER by origin.id, ancestors.lft
                ) ancestors
              GROUP BY id
            SQL
          end
        end

        link :self,
             path: { api: :project, params: %w(id) },
             column: -> { :id },
             title: -> { :name }

        link :ancestors,
             sql: -> { 'ancestors' },
             join: {
               table: :ancestors,
               condition: 'ancestors.id = projects.id',
               select: 'ancestors'
             }

        property :_type,
                 representation: ->(*) { "'Project'" }

        property :id

        property :name
      end
    end
  end
end

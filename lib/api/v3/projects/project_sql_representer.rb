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
    module Projects
      class ProjectSqlRepresenter
        include API::Decorators::Sql::Hal

        class << self
          def ctes(walker_result)
            {
              visible_projects: visible_projects_sql,
              ancestors: ancestors_sql(walker_result)
            }
          end

          protected

          def visible_projects_sql
            Project.visible.to_sql
          end

          def ancestors_sql(walker_result)
            <<-SQL.squish
              SELECT id, CASE WHEN count(link) = 0 THEN '[]' ELSE json_agg(link) END ancestors
              FROM
                (
                  SELECT
                    origin.id,
                    #{ancestor_projection} link
                  FROM projects origin
                  LEFT OUTER JOIN projects ancestors
                  ON ancestors.lft < origin.lft AND ancestors.rgt > origin.rgt
                  WHERE origin.id IN (#{origin_subselect(walker_result).select(:id).to_sql})
                  ORDER by origin.id, ancestors.lft
                ) ancestors
              GROUP BY id
            SQL
          end

          def origin_subselect(walker_result)
            if walker_result.page_size
              walker_result.filter_scope.limit(sql_limit(walker_result)).offset(sql_offset(walker_result))
            else
              walker_result.filter_scope
            end
          end

          def ancestor_projection
            if User.current.admin?
              <<-SQL.squish
                CASE
                  WHEN ancestors.id IS NOT NULL
                    THEN json_build_object('href', format('#{api_v3_paths.project('%s')}', ancestors.id),
                                           'title', ancestors.name)
                  ELSE NULL
                END
              SQL
            else
              <<-SQL.squish
                CASE
                  WHEN ancestors.id IS NOT NULL AND ancestors.id IN (SELECT id FROM visible_projects)
                    THEN json_build_object('href', format('#{api_v3_paths.project('%s')}', ancestors.id),
                                           'title', ancestors.name)
                  WHEN ancestors.id IS NOT NULL AND ancestors.id NOT IN (SELECT id FROM visible_projects)
                    THEN json_build_object('href', '#{API::V3::URN_UNDISCLOSED}',
                                           'title', #{ActiveRecord::Base.connection.quote(I18n.t(:"api_v3.undisclosed.ancestor"))})
                  ELSE NULL
                END
              SQL
            end
          end
        end

        link :self,
             path: { api: :project, params: %w(id) },
             column: -> { :id },
             title: -> { :name }

        link :ancestors,
             sql: -> { "ancestors" },
             join: {
               table: :ancestors,
               condition: "ancestors.id = projects.id",
               select: "ancestors"
             }

        property :_type,
                 representation: ->(*) { "'Project'" }

        property :id

        property :name

        property :identifier

        property :active

        property :public
      end
    end
  end
end

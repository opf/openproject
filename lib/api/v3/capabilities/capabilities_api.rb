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
  module V3
    module Capabilities
      class CapabilitiesAPI < ::API::OpenProjectAPI
        resources :capabilities do
          helpers do
            def capability_class
              @capability_class ||= Struct.new(:id, :principal_id, :context_id, :principal, :context)
            end

            def raw_capabilities
              capabilities_sql = <<~SQL
                (SELECT
                  role_permissions.permission,
                  permission_maps.permission_map,
                  members.user_id user_id,
                  members.project_id project_id
                FROM "roles"
                INNER JOIN "role_permissions" ON "role_permissions"."role_id" = "roles"."id"
                LEFT OUTER JOIN "member_roles" ON "member_roles".role_id = roles.id
                LEFT OUTER JOIN "members" ON members.id = member_roles.member_id
                JOIN
                  (SELECT * FROM (VALUES ('manage_user', 'users/create'),
                                         ('manage_user', 'users/update'),
                                         ('manage_members', 'memberships/create')) AS t(permission, permission_map)) AS permission_maps
                  ON permission_maps.permission = role_permissions.permission) capabilities
              SQL

              @raw_capabilities ||= Capability
                                      .select('capabilities.*')
                                      .from(capabilities_sql)
                                      .includes(:project, :principal)
                                      .order(permission_map: :asc)
              #.pluck('capabilities.permission', 'capabilities.permission_map', 'capabilities.principal_id', 'capabilities.context_id')
              #.zip([:permission, :permission_map, :principal_id, :context_id])
# <<~SQL
#                ORDER BY permission_maps.permission_map ASC
#              SQL
            end

            def capabilities_sql
              <<~SQL
                WITH

                all_elements AS (SELECT capabilities.* FROM (SELECT
                    permission_maps.permission_map,
                    members.user_id principal_id,
                    members.project_id project_id
                  FROM "roles"
                  INNER JOIN "role_permissions" ON "role_permissions"."role_id" = "roles"."id"
                  LEFT OUTER JOIN "member_roles" ON "member_roles".role_id = roles.id
                  LEFT OUTER JOIN "members" ON members.id = member_roles.member_id
                  JOIN
                    (SELECT * FROM (VALUES ('manage_user', 'users/create'),
                                           ('manage_user', 'users/update'),
                                           ('manage_members', 'memberships/create')) AS t(permission, permission_map)) AS permission_maps
                    ON permission_maps.permission = role_permissions.permission) capabilities),

                raw AS (SELECT * FROM all_elements
                 ORDER BY "permission_map" ASC LIMIT 50 OFFSET 1
                ),

                elements_json AS (SELECT
                  json_build_object('_links',
                    json_build_object(
                    'self', json_build_object('href', (CASE
                                                       WHEN project_id IS NULL THEN 'api/v3/capabilities/' || permission_map || '/g-' || principal_id
                                                       ELSE 'api/v3/capabilities/' || permission_map || '/p' || project_id || '-' || principal_id
                                                       END)),
                      'context', json_build_object('href', (CASE
                                                            WHEN project_id IS NULL THEN 'api/v3/capabilities/contexts/global'
                                                            ELSE 'api/v3/projects/' || project_id
                                                            END)),
                    -- TODO: differentiate between various principals
                    'principal', json_build_object('href', 'api/v3/users/' || principal_id)),
                  'id', (CASE
                         WHEN project_id IS NULL THEN permission_map || '/g-' || principal_id
                         ELSE permission_map || '/p' || project_id || '-' || principal_id
                         END)
                  ) representation
                    FROM raw
                  ),

                  collection AS (SELECT
                    json_build_object(
                      '_type', 'Collection',
                      'perPage', 50,
                      'offset', 1,
                      'count', COUNT(*),
                      'total', (SELECT COUNT(*) from all_elements),
                      '_embedded', json_build_object(
                        'elements', array_agg(representation)
                      )
                    ) json
                    FROM elements_json
                  )

                SELECT json FROM collection
              SQL
            end

            def capabilities
              ::Capability.connection.select_one capabilities_sql
            end
          end

          #get do
          #  # TODO: fix pagination


          #  Capabilities::CapabilityCollectionRepresenter
          #    .new(capabilities,
          #         self_link: api_v3_paths.capabilities,
          #         current_user: current_user,
          #         page: 1,
          #         per_page: 50)
          #end

          #get &::API::V3::Utilities::Endpoints::Index.new(model: Capability)
          #                                           .mount
          get do
            capabilities['json']
          end

          namespace :contexts do
            mount API::V3::Capabilities::Contexts::GlobalAPI
          end
        end
      end
    end
  end
end

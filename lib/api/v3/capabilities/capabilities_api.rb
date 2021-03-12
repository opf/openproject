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
          helpers API::Utilities::PageSizeHelper

          helpers do
            def capabilities_sql
              <<~SQL
                WITH

                all_elements AS (
                  #{::Queries::Capabilities::CapabilityQuery.new(user: current_user).results.to_sql}
                ),

                page_elements AS (
                  SELECT * FROM all_elements LIMIT #{resulting_page_size(params[:pageSize])} OFFSET #{to_i_or_nil(params[:offset]) || 0}
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
                  FROM page_elements
                ),

                collection AS (SELECT
                  json_build_object(
                    '_type', 'Collection',
                    'perPage', #{resulting_page_size(params[:pageSize])},
                    'offset', #{(to_i_or_nil(params[:offset]) || 0) + 1},
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
            ::API::V3::Utilities::SqlRepresenterWalker
              .new(::Queries::Capabilities::CapabilityQuery.new(user: current_user).results,
                   embed: { 'elements' => {} },
                   select: { 'elements' => { 'id' => {}, 'self' => {}, 'context' => {}, 'principal' => {} } },
                   current_user: current_user)
              .walk(API::V3::Capabilities::CapabilitySqlCollectionRepresenter)
            #capabilities['json']
          end

          namespace :contexts do
            mount API::V3::Capabilities::Contexts::GlobalAPI
          end
        end
      end
    end
  end
end

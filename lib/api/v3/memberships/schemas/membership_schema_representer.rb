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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Memberships
      module Schemas
        class MembershipSchemaRepresenter < ::API::Decorators::SchemaRepresenter
          def initialize(represented, self_link = nil, current_user: nil, form_embedded: false)
            super(represented,
                  self_link,
                  current_user: current_user,
                  form_embedded: form_embedded)
          end

          schema :id,
                 type: 'Integer'

          schema :created_at,
                 type: 'DateTime'

          schema_with_allowed_link :project,
                                   has_default: false,
                                   required: true,
                                   href_callback: ->(*) {
                                     allowed_projects_href
                                   }

          schema_with_allowed_link :principal,
                                   has_default: false,
                                   required: true,
                                   href_callback: ->(*) {
                                     allowed_principal_href
                                   }

          schema_with_allowed_link :roles,
                                   type: '[]Role',
                                   name_source: :role,
                                   has_default: false,
                                   required: true,
                                   href_callback: ->(*) {
                                     api_v3_paths.path_for(:roles, filters: [{ unit: { operator: '=', values: ['project'] } }])
                                   }

          def self.represented_class
            Member
          end

          def allowed_projects_href
            return unless represented.new_record?

            api_v3_paths.path_for(:memberships_available_projects, filters: allowed_projects_filters)
          end

          def allowed_projects_filters
            if represented.principal
              [{ principal: { operator: '!', values: [represented.principal.id.to_s] } }]
            end
          end

          def allowed_principal_href
            return unless represented.new_record?

            api_v3_paths.path_for(:principals, filters: allowed_principals_filters)
          end

          def allowed_principals_filters
            statuses = [Principal::STATUSES[:locked].to_s]
            status_filter = { status: { operator: '!', values: statuses } }

            filters = [status_filter]

            if represented.project
              member_filter = { member: { operator: '!', values: [represented.project.id.to_s] } }

              filters << member_filter
            end

            filters
          end
        end
      end
    end
  end
end

#-- encoding: UTF-8

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

module Capabilities::Scopes
  module Default
    extend ActiveSupport::Concern

    class_methods do
      # Currently, this does not reflect the behaviour present in the backend that every permission in at least one project
      # leads to having that permission in the global context as well. Hopefully, this is not necessary to be added.
      def default
        capabilities_sql = <<~SQL
          (SELECT DISTINCT
            permission_maps.permission_map,
            users.id principal_id,
            projects.id context_id
          FROM "roles"
          JOIN "role_permissions" ON "role_permissions"."role_id" = "roles"."id"
          JOIN
            (SELECT * FROM (VALUES #{action_map}) AS t(permission, permission_map)) AS permission_maps
            ON permission_maps.permission = role_permissions.permission
          LEFT OUTER JOIN "member_roles" ON "member_roles".role_id = roles.id
          LEFT OUTER JOIN "members" ON members.id = member_roles.member_id
          LEFT OUTER JOIN "projects"
            ON "projects".id = members.project_id
            OR "roles".builtin = #{Role::BUILTIN_NON_MEMBER}
          JOIN "users"
            ON "users".id = members.user_id
            OR "roles".builtin = #{Role::BUILTIN_NON_MEMBER}
              AND ("projects".public = true OR EXISTS (SELECT 1
                                                       FROM members
                                                       WHERE members.project_id = projects.id
                                                       AND members.user_id = users.id
                                                       LIMIT 1))
            OR "roles".type = 'GlobalRole'
          ) capabilities
        SQL

        Capability
          .select('capabilities.*')
          .from(capabilities_sql)
      end

      private

      def action_map
        OpenProject::AccessControl
          .contract_actions_map
          .map { |k, v| v.map { |vk, vv| vv.map { |vvv| "('#{k}', '#{action_v3_name(vk)}/#{vvv}')" } } }
          .flatten
          .join(', ')
      end

      def action_v3_name(name)
        API::Utilities::PropertyNameConverter.from_ar_name(name.to_s.singularize).pluralize
      end
    end
  end
end

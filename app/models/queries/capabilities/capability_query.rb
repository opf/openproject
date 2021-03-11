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

class Queries::Capabilities::CapabilityQuery < Queries::BaseQuery
  def self.model
    Capability
  end

  def results
    super
      .includes(:project, :principal)
      .reorder(permission_map: :asc)
  end

  def default_scope
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

    Capability
      .select('capabilities.*')
      .from(capabilities_sql)
  end
end

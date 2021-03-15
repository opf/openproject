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
    #.includes(:context, :principal)
      .reorder('permission_map ASC', 'principal_id ASC', 'capabilities.project_id ASC')
  end

  def default_scope
    capabilities_sql = <<~SQL
      (SELECT
        role_permissions.permission,
        permission_maps.permission_map,
        members.user_id principal_id,
        members.project_id project_id
      FROM "roles"
      INNER JOIN "role_permissions" ON "role_permissions"."role_id" = "roles"."id"
      LEFT OUTER JOIN "member_roles" ON "member_roles".role_id = roles.id
      LEFT OUTER JOIN "members" ON members.id = member_roles.member_id
      JOIN
        (SELECT * FROM (VALUES #{action_map}) AS t(permission, permission_map)) AS permission_maps
        ON permission_maps.permission = role_permissions.permission) capabilities
    SQL

    Capability
      .select('capabilities.*')
      .from(capabilities_sql)
  end

  private

  def action_map
    OpenProject::AccessControl
      .contract_actions_map
      .map { |k, v| v.map { |vk, vv| vv.map { |vvv| "('#{k}', '#{v3_name(vk)}/#{vvv}')" } } }
      .flatten
      .join(', ')
  end

  def v3_name(name)
    # TODO: There is a already a class for translations
    if name.to_s == 'members'
      'memberships'
    else
      name
    end
  end

  #def apply_orders(scope)
  #  orders.each do |order|
  #    scope = scope.merge(order.scope)
  #  end

  #  scope

  #  # To get deterministic results, especially when paginating (limit + offset)
  #  # an order needs to be prepended that is ensured to be
  #  # different between all elements.
  #  # Without such a criteria, results can occur on multiple pages.
  #  #already_ordered_by_id?(scope) ? scope : scope.order(id: :desc)
  #end
end

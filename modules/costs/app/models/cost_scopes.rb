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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CostScopes
  def visible(*args)
    user = args.first || User.current
    with_visible_entries_on self, user:, project: args[1]
  end

  def visible_costs(*args)
    user = args.first || User.current
    with_visible_costs_on self, user:, project: args[1]
  end

  def view_allowed_entries_permission
    raise SubclassResponsibilityError
  end

  def view_allowed_own_entries_permission
    raise SubclassResponsibilityError
  end

  def view_rates_permissions
    raise SubclassResponsibilityError
  end

  def with_visible_costs_on(scope, user: User.current, project: nil)
    with_visible_entries = with_visible_entries_on(scope, user:, project:)
    with_visible_rates_on with_visible_entries, user:
  end

  def with_visible_entries_on(scope, user: User.current, project: nil)
    table = arel_table

    visible_scope = scope.where(
      view_or_view_own(table, view_allowed_entries_permission, view_allowed_own_entries_permission, user)
    )

    if project
      visible_scope.where(project_id: project.id)
    else
      visible_scope
    end
  end

  def view_or_view_own(table, allowed_permission, allowed_own_permission, user) # rubocop:disable Metrics/AbcSize
    project_allowed_scope = table[:project_id].in(Project.allowed_to(user, allowed_permission).select(:id).arel)

    # We allow some of the `_own_` permissions on the WorkPackage, but others only on the project,
    # so we need to figure out the correct scope to use
    wp_scoped_permission = Authorization.permissions_for(allowed_own_permission).any?(&:work_package?)

    # TODO: Add other entity types
    if wp_scoped_permission
      project_allowed_scope.or(
        table[:entity_type].eq("WorkPackage").and(
          table[:entity_id]
          .in(WorkPackage.allowed_to(user, allowed_own_permission).select(:id).arel)
          .and(table[:user_id].eq(user.id))
        )
      )
    else
      project_allowed_scope.or(
        table[:project_id]
        .in(Project.allowed_to(user, allowed_own_permission).select(:id).arel)
        .and(table[:user_id].eq(user.id))
      )
    end
  end

  def with_visible_rates_on(scope, user: User.current)
    table = arel_table
    view_allowed = Project.allowed_to(user, view_rates_permissions).select(:id)

    scope.where(table[:project_id].in(view_allowed.arel))
  end
end

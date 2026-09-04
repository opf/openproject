# frozen_string_literal: true

# -- copyright
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
# ++

module Projects::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      # Returns all projects the user is allowed to see.
      # Those include projects where the user has the permission:
      # * :view_project via a project role (which might also be the non member/anonymous role) or by being administrator
      # * :view_work_packages via a work package role
      def visible(user = User.current)
        # Use a shortcut for admins and anonymous where
        # we don't need to calculate for work package roles which is more expensive
        if user.active_admin? || user.anonymous?
          allowed_to(user, :view_project)
        else
          active.public_projects.or(active.where(id: user.members.select(:project_id)))
        end
      end

      # Ids of the projects visible to +user+, for use as a semi-join operand:
      # +where(project_id: Project.visible_ids(user))+.
      #
      # With +shared_permissions_cte+ on, the set is wrapped in an +AS MATERIALIZED+
      # CTE and built once instead of re-derived per row; off, it is the plain
      # +visible(user).select(:id)+ subquery. Both return the same ids. The nested
      # inner CTE only carries the materialization hint (see
      # +WorkPackages::Scopes::AllowedTo.visible_ids+).
      def visible_ids(user = User.current)
        ids = visible(user).select(:id)

        return ids unless OpenProject::FeatureDecisions.shared_permissions_cte_active?

        visible_projects = Arel::Table.new(:visible_projects)

        with(visible_projects: Arel.sql(<<~SQL.squish))
          WITH materialized_visible_projects AS MATERIALIZED (
            #{ids.to_sql}
          )
          SELECT id FROM materialized_visible_projects
        SQL
          .select(visible_projects[:id])
          .from(visible_projects)
      end
    end
  end
end

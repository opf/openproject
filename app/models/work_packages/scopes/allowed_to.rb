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

module WorkPackages::Scopes
  module AllowedTo
    extend ActiveSupport::Concern

    class_methods do
      # Returns an ActiveRecord::Relation to find all work packages for which
      # +user+ has the given +permission+ either directly on the work package
      # or by the linked project
      def allowed_to(user, permission) # rubocop:disable Metrics/PerceivedComplexity
        permissions = Authorization.contextual_permissions(permission, :work_package, raise_on_unknown: true)

        return none if user.locked? || user.deleted?
        return none if permissions.empty?

        if user.admin? && permissions.all?(&:grant_to_admin?)
          admin_allowed_to(permissions)
        elsif user.anonymous?
          anonymous_allowed_to(user, permissions)
        else
          logged_in_non_admin_allowed_to(user, permissions)
        end
      end

      private

      def admin_allowed_to(permissions)
        where(id: allowed_to_admin_relation(permissions))
      end

      def anonymous_allowed_to(user, permissions)
        where(project_id: Project.allowed_to(user, permissions))
      end

      # The body of the member_projects CTE. With the shared-permissions CTE feature on, the union is
      # emitted as a provider so identical member_projects derivations repeated across one query
      # collapse into a single hoisted CTE; otherwise the union SQL is embedded inline as before.
      def member_projects_cte_body(user, permissions)
        if OpenProject::FeatureDecisions.shared_user_permissions_cte_active?
          Project.unscoped.allowed_to_member_union_provider(user, permissions, entity_types: [WorkPackage.name])
        else
          union = Project.unscoped.allowed_to_member_union(user, permissions, entity_types: [WorkPackage.name])
          Arel.sql(union.to_sql)
        end
      end

      def logged_in_non_admin_allowed_to(user, permissions)
        # Get all projects a user has the permissions in.
        # Permissions can come from project memberships as well as entity/work_package memberships, in addition
        # to (UNION) potentially the non-member permissions.
        # This comes back with the columns
        # * id (of the project) - this column will always be set regardless of whether the membership is entity-specific or not.
        # * entity_id (of the work package) - this column can be null in case it is a project-wide membership.
        member_projects_cte = member_projects_cte_body(user, permissions)

        # Split the member projects into two distinct sets
        # for easier reference.
        entity_member_projects = Arel.sql(<<~SQL.squish)
          SELECT *
          FROM member_projects
          WHERE entity_id IS NOT NULL
        SQL

        project_member_projects = Arel.sql(<<~SQL.squish)
          SELECT *
          FROM member_projects
          WHERE entity_id IS NULL
        SQL

        # Take all work packages allowed by either project-wide or entity-specific membership.
        # PostgreSQL however sometimes turns to a sequential scan with the query above.
        #
        # It is currently unclear if index scans can still happen in the combination of the CTE with the check
        # outside of the CTEs for the existence of any record.
        # This happened in the past, before changing this CTE to a UNION, in case AR.exists? is used which adds a LIMIT 1
        # to the query. In this case, there is a known shortcoming that PostgreSQL's query planner
        # will make poor choices
        # (https://www.postgresql.org/message-id/flat/CA%2BU5nMLbXfUT9cWDHJ3tpxjC3bTWqizBKqTwDgzebCB5bAGCgg%40mail.gmail.com).
        #
        # Once AR supports adding materialization hints (https://github.com/rails/rails/pull/54322), the inner
        # `allowed` CTE can be abandoned as it is only used for being able to provide such a hint.
        # Having the inner materialized CTE has no known negative side effects which is why it is kept.
        allowed_by_projects_and_work_packages = Arel.sql(<<~SQL.squish)
          WITH allowed AS MATERIALIZED (
            SELECT
              work_packages.id
            FROM
              work_packages
            JOIN project_member_projects ON project_member_projects.id	= work_packages.project_id

            UNION

            SELECT
              work_packages.id
            FROM
              work_packages
            JOIN entity_member_projects ON entity_member_projects.entity_id = work_packages.id
          )

          SELECT * from allowed
        SQL

        with(member_projects: member_projects_cte,
             entity_member_projects:,
             project_member_projects:,
             allowed_by_projects_and_work_packages:)
          .where(<<~SQL.squish)
            EXISTS (
              SELECT 1
              FROM allowed_by_projects_and_work_packages
              WHERE work_packages.id = allowed_by_projects_and_work_packages.id
            )
          SQL
      end

      def allowed_to_admin_relation(permissions)
        unscoped
        .joins(:project)
        .joins(allowed_to_enabled_module_join(permissions))
          .where(Project.arel_table[:active].eq(true))
      end

      def allowed_to_enabled_module_join(permissions) # rubocop:disable Metrics/AbcSize
        project_module = permissions.filter_map(&:project_module).uniq
        enabled_module_table = EnabledModule.arel_table
        projects_table = Project.arel_table

        if project_module.any?
          arel_table.join(enabled_module_table, Arel::Nodes::InnerJoin)
                    .on(projects_table[:id].eq(enabled_module_table[:project_id])
                          .and(enabled_module_table[:name].in(project_module))
                          .and(projects_table[:active].eq(true)))
                    .join_sources
        end
      end
    end
  end
end

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

      def logged_in_non_admin_allowed_to(user, permissions)
        project_ids, work_package_ids = member_project_and_work_package_ids(user, permissions)

        where(arel_table[:project_id].in(project_ids).or(arel_table[:id].in(work_package_ids)))
      end

      def member_project_and_work_package_ids(user, permissions)
        member_projects = Project
                            .unscoped
                            .allowed_to_member_union(user, permissions, entity_types: [nil, WorkPackage.name])

        # Plucking the ids is deliberate here.
        # We were confused by it ourselves, but with a subquery, PostgreSQL does not always optimize the query,
        # so the second roundtrip is almost always faster.
        # Please see the following PR for references
        # https://github.com/opf/openproject/pull/26131#issuecomment-6270068603
        project_rows, work_package_rows = Project
                                            .unscoped
                                            .from(Arel::Nodes::TableAlias.new(Arel::Nodes::Grouping.new(member_projects),
                                                                              "member_projects"))
                                            .pluck("member_projects.id", "member_projects.entity_id")
                                            .partition { |_, entity_id| entity_id.nil? }

        [project_rows.map(&:first).uniq, work_package_rows.map(&:last).uniq]
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

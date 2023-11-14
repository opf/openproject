# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
      def allowed_to(user, permission) # rubocop:disable Metrics/AbcSize
        permissions = Authorization.contextual_permissions(permission, :work_package, raise_on_unknown: true)

        return none if user.locked?
        return none if permissions.empty?

        if user.admin? && permissions.all?(&:grant_to_admin?)
          where(id: allowed_to_admin_relation(permissions))
        elsif user.anonymous?
          where(project_id: Project.allowed_to(user, permission).select(:id))
        else
          where(arel_table[:id].in(allowed_to_member_relation(user, permissions).select(work_package_table[:id]).arel)).or(
            where(arel_table[:project_id].in(Project.allowed_to(user, permissions).select(:id).arel))
          )
        end
      end

      private

      def work_package_table
        return @work_package_table if defined?(@work_package_table)

        @work_package_table = arel_table.dup
        @work_package_table.table_alias = 'authorized_work_packages'
        @work_package_table
      end

      def allowed_to_admin_relation(permissions)
        joins(:project)
        .joins(allowed_to_enabled_module_join(permissions))
          .where(Project.arel_table[:active].eq(true))
      end

      def allowed_to_member_relation(user, permissions)
        Member
          .joins(allowed_to_member_in_work_package_join)
          .joins(allowed_to_member_in_active_project_join(user))
          .joins(allowed_to_enabled_module_join(permissions))
          .joins(:roles, :member_roles)
          .joins(allowed_to_role_permission_join(permissions))
          .select(work_package_table[:id])
      end

      def allowed_to_enabled_module_join(permissions) # rubocop:disable Metrics/AbcSize
        project_module = permissions.filter_map(&:project_module).uniq
        enabled_module_table = EnabledModule.arel_table
        projects_table = Project.arel_table

        if project_module.any?
          work_package_table.join(enabled_module_table, Arel::Nodes::InnerJoin)
                    .on(projects_table[:id].eq(enabled_module_table[:project_id])
                          .and(enabled_module_table[:name].in(project_module))
                          .and(projects_table[:active].eq(true)))
                    .join_sources
        end
      end

      def allowed_to_role_permission_join(permissions) # rubocop:disable Metrics/AbcSize
        return if permissions.all?(&:public?)

        role_permissions_table = RolePermission.arel_table
        enabled_modules_table = EnabledModule.arel_table
        roles_table = Role.arel_table

        condition = permissions.inject(Arel::Nodes::False.new) do |or_condition, permission|
          permission_condition = role_permissions_table[:permission].eq(permission.name)

          if permission.project_module.present?
            permission_condition = permission_condition.and(enabled_modules_table[:name].eq(permission.project_module))
          end

          or_condition.or(permission_condition)
        end

        work_package_table
          .join(role_permissions_table, Arel::Nodes::InnerJoin)
          .on(roles_table[:id].eq(role_permissions_table[:role_id])
                              .and(condition))
          .join_sources
      end

      def allowed_to_members_condition(user)
        members_table = Member.arel_table

        members_table[:project_id].eq(work_package_table[:project_id])
                                  .and(members_table[:user_id].eq(user.id))
                                  .and(members_table[:entity_type].eq(model_name.name))
      end

      def allowed_to_member_in_active_project_join(user)
        Project.arel_table
          .join(Project.arel_table)
                  .on(Project.arel_table[:active].eq(true)
                   .and(allowed_to_members_condition(user)))
                  .join_sources
      end

      def allowed_to_member_in_work_package_join
        members_table = Member.arel_table
        work_package_table.join(work_package_table)
        .on(members_table[:entity_id].eq(work_package_table[:id]).and(members_table[:entity_type].eq(model_name.name)))
        .join_sources
      end
    end
  end
end

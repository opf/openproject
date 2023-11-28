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

module Projects::Scopes
  module AllowedTo
    extend ActiveSupport::Concern

    class_methods do
      # Returns an ActiveRecord::Relation to find all entries for which
      # +user+ has the given +permission+.
      def allowed_to(user, permission)
        permissions = allowed_to_permissions(permission)

        return none if user.locked?
        return none if permissions.empty?

        if user.admin? && permissions.all?(&:grant_to_admin?)
          allowed_to_admin(permissions)
        elsif user.anonymous?
          allowed_to_anonymous(user, permissions)
        else
          allowed_to_member(user, permissions)
        end
      end

      private

      def allowed_to_non_member_relation(user, permissions)
        joins(allowed_to_enabled_module_join(permissions))
          .joins(allowed_to_builtin_roles_in_active_project_join(user))
          .joins(allowed_to_role_permission_join(permissions))
      end

      def allowed_to_builtin_roles_in_active_project_join(user)
        condition = allowed_to_built_roles_in_active_project_condition(user)

        if user.logged?
          condition = condition.and(allowed_to_no_member_exists_condition(user))
        end

        roles_table = Role.arel_table

        arel_table.join(roles_table)
                  .on(condition)
                  .join_sources
      end

      def allowed_to_built_roles_in_active_project_condition(user)
        builtin = if user.logged?
                    Role::BUILTIN_NON_MEMBER
                  else
                    Role::BUILTIN_ANONYMOUS
                  end

        roles_table = Role.arel_table

        roles_table[:builtin].eq(builtin)
                             .and(arel_table[:active])
                             .and(arel_table[:public])
      end

      def allowed_to_no_member_exists_condition(user)
        Member
          .select(1)
          .where(member_conditions(user))
          .where(Member.arel_table[:project_id].eq(arel_table[:id]))
          .arel
          .exists
          .not
      end

      def allowed_to_admin(permissions)
        where(id: allowed_to_admin_relation(permissions))
      end

      def allowed_to_anonymous(user, permissions)
        where(id: allowed_to_non_member_relation(user, permissions))
      end

      def allowed_to_member(user, permissions)
        allowed_via_membership = allowed_to_member_relation(user, permissions).select(arel_table[:id]).arel
        allowed_via_non_member = allowed_to_non_member_relation(user, permissions).select(:id).arel

        where(arel_table[:id].in(Arel::Nodes::UnionAll.new(allowed_via_membership, allowed_via_non_member)))
      end

      def allowed_to_admin_relation(permissions)
        joins(allowed_to_enabled_module_join(permissions))
          .where(Project.arel_table[:active].eq(true))
      end

      def allowed_to_member_relation(user, permissions)
        Member
          .where(member_conditions(user))
          .joins(allowed_to_member_in_active_project_join)
          .joins(allowed_to_enabled_module_join(permissions))
          .joins(:roles)
          .joins(allowed_to_role_permission_join(permissions))
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

        arel_table
          .join(role_permissions_table, Arel::Nodes::InnerJoin)
          .on(roles_table[:id].eq(role_permissions_table[:role_id])
                              .and(condition))
          .join_sources
      end

      def allowed_to_member_in_active_project_join
        Member.arel_table
               .join(Project.arel_table)
               .on(Project.arel_table[:active].eq(true)
                          .and(Member.arel_table[:project_id].eq(arel_table[:id])))
               .join_sources
      end

      def member_conditions(user)
        Member.arel_table[:user_id].eq(user.id)
        .and(Member.arel_table[:entity_id].eq(nil))
        .and(Member.arel_table[:entity_type].eq(nil))
      end

      def allowed_to_permissions(permission)
        Authorization.contextual_permissions(permission,
                                             to_s.underscore.to_sym,
                                             raise_on_unknown: true)
      end
    end
  end
end

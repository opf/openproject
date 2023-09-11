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
      # Returns an ActiveRecord::Relation to find all projects for which
      # +user+ has the given +permission+
      def allowed_to(user, permission)
        permissions = allowed_to_permissions(permission)

        if user.admin?
          Project.where(id: allowed_to_admin_relation(permissions))
        elsif user.anonymous?
          Project.where(id: allowed_to_non_member_relation(user, permissions))
        else
          Project.where(Project.arel_table[:id].in(allowed_to_member_relation(user, permissions).arel.union(
                                                     allowed_to_non_member_relation(user, permissions).arel
                                                   )))
        end
      end

      private

      def allowed_to_admin_relation(permissions)
        Project
          .joins(allowed_to_enabled_module_join(permissions))
          .where(active: true)
      end

      def allowed_to_non_member_relation(user, permissions)
        builtin = if user.logged?
                    Role::BUILTIN_NON_MEMBER
                  else
                    Role::BUILTIN_ANONYMOUS
                  end

        member_permission = if user.logged?
                              <<~SQL.squish
                                AND NOT EXISTS (SELECT 1
                                                FROM members
                                                WHERE #{allowed_to_members_condition(user)})
                              SQL
                            end

        Project
          .joins(allowed_to_enabled_module_join(permissions))
          .joins(<<~SQL.squish
            INNER JOIN "roles"
              ON "roles"."builtin" = #{builtin}
              AND "projects"."active" = TRUE
              AND "projects"."public" = TRUE
              #{member_permission}
          SQL
                )
          .joins(allowed_to_role_permission_join(permissions))
          .select(:id)
      end

      def allowed_to_member_relation(user, permissions)
        Project
          .joins(allowed_to_enabled_module_join(permissions))
          .joins(<<~SQL.squish
            JOIN "members"
              ON "projects"."active" = TRUE
              AND #{allowed_to_members_condition(user)}
          SQL
                )
          .joins('JOIN "member_roles" ON "members"."id" = "member_roles"."member_id"')
          .joins('JOIN "roles" ON member_roles.role_id = roles.id')
          .joins(allowed_to_role_permission_join(permissions))
          .select(:id)
      end

      def allowed_to_enabled_module_join(permissions)
        project_module = permissions.filter_map(&:project_module).uniq

        if project_module.any?
          sql = <<~SQL.squish
            INNER JOIN "enabled_modules"
              ON "projects"."id" = "enabled_modules"."project_id"
              AND "enabled_modules"."name" IN (:enabled_module_names)
              AND "projects"."active" = TRUE
          SQL

          OpenProject::SqlSanitization.sanitize(sql,
                                                enabled_module_names: project_module)
        end
      end

      def allowed_to_role_permission_join(permissions)
        return if permissions.all?(&:public?)

        condition = permissions.map do |permission|
          if permission.public?
            <<~SQL.squish
              "role_permissions"."permission" = '#{permission.name}'
            SQL
          else
            <<~SQL.squish
              (enabled_modules.name = '#{permission.project_module}' AND "role_permissions"."permission" = '#{permission.name}')
            SQL
          end
        end.join(' OR ')

        <<~SQL.squish
          JOIN "role_permissions"
            ON roles.id = role_permissions.role_id
            AND (#{condition})
        SQL
      end

      def allowed_to_permissions(permission)
        if permission.is_a?(Hash)
          OpenProject::AccessControl.allow_actions(permission)
        else
          [OpenProject::AccessControl.permission(permission)].compact
        end
      end

      def allowed_to_members_condition(user)
        <<~SQL.squish
          members.project_id = projects.id
          AND members.user_id = #{user.id}
          AND members.entity_type IS NULL
          AND members.entity_id IS NULL
        SQL
      end
    end
  end
end

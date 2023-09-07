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
      # Returns a ActiveRecord::Relation to find all projects for which
      # +user+ has the given +permission+
      def allowed_to(user, permission)
        permissions = if permission.is_a?(Hash)
                        OpenProject::AccessControl.allow_actions(permission)
                      else
                        [OpenProject::AccessControl.permission(permission)].compact
                      end

        if user.admin?
          Project
            .joins(:enabled_modules)
            .where(active: true)
            .where(enabled_modules: { name: permissions.map(&:project_module).compact.uniq })
        elsif user.anonymous?
          Project.find_by_sql(allowed_to_non_member_sql(user, permissions))
        else
          Project.find_by_sql("#{allowed_to_member_sql(user, permissions)} UNION #{allowed_to_non_member_sql(user, permissions)}")
        end
      end

      private

      def allowed_to_non_member_sql(user, permissions)
        sql = <<~SQL.squish
          SELECT "projects".*
          FROM "projects"
          #{allowed_to_enabled_module_join(permissions)}
          INNER JOIN "roles"
              ON "roles"."builtin" IN (#{Role::BUILTIN_ANONYMOUS}, #{Role::BUILTIN_NON_MEMBER})
              AND "projects"."active" = TRUE
              AND "projects"."public" = TRUE
              AND NOT EXISTS (SELECT 1
                              FROM members
                              WHERE members.project_id = projects.id
                              AND members.user_id = :user_id
                              AND members.entity_type IS NULL
                              AND members.entity_id IS NULL
                              LIMIT 1)
          #{allowed_to_role_permission_join(permissions)}
        SQL

        OpenProject::SqlSanitization.sanitize(sql,
                                              user_id: user.id,
                                              permission: permissions.map(&:name))
      end

      def allowed_to_member_sql(user, permissions)
        sql = <<~SQL.squish
          SELECT "projects".*
          FROM "projects"
          #{allowed_to_enabled_module_join(permissions)}
          JOIN "members"
              ON "projects"."id" = "members"."project_id"
              AND "members"."user_id" = :user_id
              AND "members"."entity_type" IS NULL
              AND "members"."entity_id" IS NULL
              AND "projects"."active" = TRUE
          JOIN "member_roles"
              ON "members"."id" = "member_roles"."member_id"
          JOIN "roles"
              ON "projects"."active" = TRUE
              AND ("roles"."id" = "member_roles"."role_id")
          #{allowed_to_role_permission_join(permissions)}
        SQL

        OpenProject::SqlSanitization.sanitize(sql,
                                              user_id: user.id,
                                              permission: permissions.map(&:name))
      end

      def allowed_to_enabled_module_join(permissions)
        project_module = permissions.map(&:project_module).compact.uniq

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
          <<~SQL.squish
            (enabled_modules.name = '#{permission.project_module}' AND "role_permissions"."permission" = '#{permission.name}')
          SQL
        end.join(' OR ')

        <<~SQL.squish
          JOIN "role_permissions"
              ON roles.id = role_permissions.role_id
              AND (#{condition})
        SQL
      end
    end
  end
end

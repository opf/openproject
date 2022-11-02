class PermissionMaterializedView < ActiveRecord::Migration[7.0]
  using CoreExtensions::SquishSql

  PERMISSIONS_VIEW_NAME = 'permissions'.freeze
  REFRESH_FUNCTION_NAME = 'refresh_permissions_view'.freeze

  def up
    execute <<~SQL.squish
      CREATE MATERIALIZED VIEW #{PERMISSIONS_VIEW_NAME} AS
      SELECT
        user_id,
        project_id,
        permission
      FROM
      (
        SELECT
          members.user_id,
          members.project_id,
          permission
        FROM

        -- All members (of all projects) and non members (of public projects)
        (
          -- non members
          SELECT *
          FROM
          (
            SELECT
              users.id user_id,
              projects.id project_id,
              roles.id role_id
            FROM
              users,
              projects,
              roles
            WHERE
              (
                (users.type IN ('User', 'PrincipalUser') AND roles.builtin = 1)
                OR
                (users.type IN ('AnonymousUser') AND roles.builtin = 2)
              )
            AND projects.public
              AND
                NOT EXISTS (SELECT 1 FROM members WHERE user_id = users.id AND project_id = projects.id)
            GROUP BY
              users.id,
              projects.id,
              roles.id
          ) non_members

          UNION
          -- actual members

          SELECT
            members.user_id,
            members.project_id,
            member_roles.role_id
          FROM
            members
          JOIN
            member_roles ON members.id = member_roles.member_id
        ) members,
        -- All permissions active within projects
        (
          SELECT
            permission_module_map.permission,
            project_id,
            role_permissions.role_id
          FROM
          -- Projects and the modules active therein.
          (
            SELECT
              permission_module_map.permission,
              permission_module_map.project_module,
              enabled_modules.project_id,
              public
            FROM
              -- Only permissions with a project_module required here
              (VALUES ('view_project', NULL, true), ('view_news', 'news', true), ('view_work_packages', 'work_package_tracking', false), ('add_work_packages', 'work_package_tracking', false), ('work_package_assigned', 'work_package_tracking', false), ('view_wiki_pages', 'wiki', false)) AS permission_module_map(permission, project_module, public),
              enabled_modules
              WHERE enabled_modules.name = permission_module_map.project_module

            UNION

            SELECT
              permission_module_map.permission,
              permission_module_map.project_module,
              projects.id,
              permission_module_map.public
            FROM
              -- Only permissions without a project_module required here
              (VALUES ('view_project', NULL, true), ('view_news', 'news', true), ('view_work_packages', 'work_package_tracking', false), ('add_work_packages', 'work_package_tracking', false), ('work_package_assigned', 'work_package_tracking', false), ('view_wiki_pages', 'wiki', false)) AS permission_module_map(permission, project_module, public),
              projects
              WHERE permission_module_map.project_module IS NULL
          ) permission_module_map,
          -- Roles and the permissions they grant.
          -- Includes both permissions granted because a role has it actively assigned (role_permissions) or because the
          -- permission is public.
          (
            -- permissions granted because a role as it assigned (non public permissions)
            SELECT
              permission_module_map.*,
              role_permissions.role_id
            FROM
              -- Only non public permissions required here
              (VALUES ('view_project', NULL, true), ('view_news', 'news', true), ('view_work_packages', 'work_package_tracking', false), ('add_work_packages', 'work_package_tracking', false), ('work_package_assigned', 'work_package_tracking', false), ('view_wiki_pages', 'wiki', false)) AS permission_module_map(permission, project_module, public),
              role_permissions
            WHERE permission_module_map.permission = role_permissions.permission

            UNION

            -- permissions granted because a role exists and the permission is public
            SELECT
              permission_module_map.*,
              roles.id role_id
            FROM
              -- Only public permissions required here
              (VALUES ('view_project', NULL, true), ('view_news', 'news', true), ('view_work_packages', 'work_package_tracking', false), ('add_work_packages', 'work_package_tracking', false), ('work_package_assigned', 'work_package_tracking', false), ('view_wiki_pages', 'wiki', false)) AS permission_module_map(permission, project_module, public),
              roles
            WHERE permission_module_map.public
          ) role_permissions
          WHERE
            (role_permissions.permission = permission_module_map.permission)

          GROUP BY
            permission_module_map.permission,
            role_permissions.role_id,
            project_id
        ) permissions_in_project

        WHERE
          (members.project_id = permissions_in_project.project_id)
          AND
          (members.role_id = permissions_in_project.role_id)

        UNION

        -- All permissions admins have in the projects.
        -- Cannot be done in a performant manner together with the normal users.

         SELECT
           users.id,
           projects.id,
           permission
         FROM
           users, projects, enabled_modules,
           -- Only permissions not having grant_to_admin: false required here
           (VALUES ('view_project', NULL, true), ('view_news', 'news', true), ('view_work_packages', 'work_package_tracking', false), ('add_work_packages', 'work_package_tracking', false), ('view_wiki_pages', 'wiki', false)) AS permission_module_map(permission, project_module, public)
         WHERE
           users.admin = TRUE
         AND
           enabled_modules.project_id = projects.id
         AND
           (enabled_modules.name = permission_module_map.project_module OR permission_module_map.project_module IS NULL)
      ) permissions_in_projects,
      projects,
      users
      WHERE
        -- Reduce to only those permission sets in which both project and user are active.
        permissions_in_projects.user_id = users.id
        AND
          permissions_in_projects.project_id = projects.id
        AND
          users.status = #{Principal.statuses[:active]}
        AND
          projects.active


       UNION

       -- global permissions by memberships

       SELECT
         users.id user_id,
         null project_id,
         permission_module_map.permission
       FROM
          users,
          members,
          member_roles,
          roles,
          role_permissions,
          -- only global permissions needed here
          (VALUES ('add_project')) AS permission_module_map(permission)
       WHERE
       (
         users.id = members.user_id AND members.project_id IS NULL AND members.id = member_roles.member_id AND member_roles.role_id = roles.id AND role_permissions.role_id = roles.id AND role_permissions.permission = permission_module_map.permission
       )
       AND users.status = #{Principal.statuses[:active]}
       GROUP BY users.id, permission_module_map.permission

       UNION

       -- global permissions because of admin

       SELECT
         users.id user_id,
         null project_id,
         permission_module_map.permission
       FROM
          users,
          (VALUES ('add_project')) AS permission_module_map(permission)
       WHERE
         users.admin
         AND users.status = #{Principal.statuses[:active]}
       GROUP BY users.id, permission_module_map.permission
    SQL

    add_index :permissions, %i[user_id project_id permission], unique: true
    add_index :permissions, :user_id
    add_index :permissions, :project_id
    add_index :permissions, :permission

    execute <<~SQL.squish
      CREATE OR REPLACE FUNCTION #{REFRESH_FUNCTION_NAME}() RETURNS trigger AS $function$
      BEGIN
        REFRESH MATERIALIZED VIEW #{PERMISSIONS_VIEW_NAME};
        RETURN NULL;
      END;
      $function$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER #{REFRESH_FUNCTION_NAME}_on_users
      AFTER INSERT OR UPDATE OR DELETE ON #{User.table_name}
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{REFRESH_FUNCTION_NAME}();
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER #{REFRESH_FUNCTION_NAME}_on_projects
      AFTER INSERT OR UPDATE OR DELETE ON #{Project.table_name}
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{REFRESH_FUNCTION_NAME}();
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER #{REFRESH_FUNCTION_NAME}_on_member_roles
      AFTER INSERT OR UPDATE OR DELETE ON #{MemberRole.table_name}
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{REFRESH_FUNCTION_NAME}();
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER #{REFRESH_FUNCTION_NAME}_on_enabled_modules
      AFTER INSERT OR UPDATE OR DELETE ON #{EnabledModule.table_name}
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{REFRESH_FUNCTION_NAME}();
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER #{REFRESH_FUNCTION_NAME}_on_role_permissions
      AFTER INSERT OR UPDATE OR DELETE ON #{RolePermission.table_name}
      FOR EACH STATEMENT
      EXECUTE PROCEDURE #{REFRESH_FUNCTION_NAME}();
    SQL
  end

  def down
    execute <<~SQL.squish
      DROP MATERIALIZED VIEW permissions
    SQL
  end
end

class PermissionMaterializedView < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW permissions AS
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

        -- All members and non members (of public projects)
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
            roles.id role_id
          FROM
          (
            SELECT
              permission_module_map.permission,
              permission_module_map.project_module,
              enabled_modules.project_id,
              public
            FROM
              (VALUES ('view_project', NULL, true), ('view_work_packages', 'work_package_tracking', false)) AS permission_module_map(permission, project_module, public),
              enabled_modules
              WHERE enabled_modules.name = permission_module_map.project_module

            UNION

            SELECT
              permission_module_map.permission,
              permission_module_map.project_module,
              projects.id,
              permission_module_map.public
            FROM
              (VALUES ('view_project', NULL, true), ('view_work_packages', 'work_package_tracking', false)) AS permission_module_map(permission, project_module, public),
              projects
              WHERE permission_module_map.project_module IS NULL
          ) permission_module_map,
          -- Roles and the permissions they grant
          (
            SELECT roles.*, role_permissions.permission
            FROM
              roles,
              role_permissions
            WHERE roles.id = role_permissions.role_id
          ) roles
          WHERE
            (
              (permission_module_map.public = FALSE AND roles.permission = permission_module_map.permission)
              OR
              (permission_module_map.public = TRUE)
            )

          GROUP BY
            permission_module_map.permission,
            roles.id,
            project_id
        ) permissions_in_project

        WHERE
          (members.project_id = permissions_in_project.project_id)
          AND
          (members.role_id = permissions_in_project.role_id)

        UNION

        -- All permissions admins have in the projects.
        -- Cannot be done performantly together with the normal users.

         SELECT
           users.id,
           projects.id,
           permission
         FROM
           users, projects, enabled_modules,
           (VALUES ('view_project', NULL, true), ('view_work_packages', 'work_package_tracking', false)) AS permission_module_map(permission, project_module, public)
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
          users.status = 1
        AND
          projects.active
    SQL

    add_index :permissions, %i[user_id project_id permission], unique: true
    add_index :permissions, :user_id
    add_index :permissions, :project_id
    add_index :permissions, :permission
  end

  def down
    execute <<~SQL
      DROP MATERIALIZED VIEW permissions
    SQL
  end
end

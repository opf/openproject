class PermissionMaterializedView < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW permissions AS
      SELECT
        members.user_id,
        members.project_id,
        role_permissions.permission
      FROM
        members
      JOIN
        member_roles ON members.id = member_roles.member_id
      JOIN
        roles ON roles.id = member_roles.role_id
      JOIN
        role_permissions ON roles.id = role_permissions.role_id
      JOIN
        projects ON projects.id = members.project_id AND projects.active = TRUE
      JOIN
        enabled_modules ON projects.id = enabled_modules.project_id
      JOIN
        (VALUES ('view_work_packages', 'work_package_tracking')) AS permission_module_map(permission, project_module)
        ON permission_module_map.permission = role_permissions.permission
        AND (enabled_modules.name = permission_module_map.project_module OR permission_module_map.project_module IS NULL)

      UNION

      -- active member users get public permissions as long as the corresponding module is active and the project as well

      SELECT DISTINCT
        members.user_id,
        members.project_id,
        permission_module_map.permission
      FROM
        members
      JOIN
        member_roles ON members.id = member_roles.member_id
      JOIN
        projects ON projects.id = members.project_id AND projects.active = TRUE
      JOIN
        enabled_modules ON projects.id = enabled_modules.project_id
      CROSS JOIN
        (VALUES ('view_project', NULL)) AS permission_module_map(permission, project_module)
      WHERE
        enabled_modules.name = permission_module_map.project_module	OR permission_module_map.project_module IS NULL

      UNION

      -- active admin users get all permissions as long as corresponding module is active and the project as well
      SELECT
        users.id,
        projects.id,
        permission
      FROM
        users, projects
      CROSS JOIN
        -- TODO fetch values from OpenProject::AccessControl.permissions.map { |p| [p.name, p.project_module] }
        (VALUES ('view_work_packages', 'work_package_tracking')) AS permission_module_map(permission, project_module)
      WHERE
        users.admin = TRUE

      UNION

      -- In public projects, all users not being a member have the non member permission. That includes the anonymous user
      -- which can never be a member anyway.

     SELECT user_id, non_members.project_id, permission
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
             (users.type IN ('User', 'PrincipalUser') AND roles.builtin = #{Role::BUILTIN_NON_MEMBER})
             OR
             (users.type IN ('AnonymousUser') AND roles.builtin = #{Role::BUILTIN_ANONYMOUS})
           )
         AND projects.public
             AND
               NOT EXISTS (SELECT 1 FROM members WHERE user_id = users.id AND project_id = projects.id)
         GROUP BY
            users.id,
           projects.id,
           roles.id
       ) non_members,
       (
SELECT
         permission_module_map.permission,
           project_id,
           roles.id role_id
FROM
		   (
			   SELECT * FROM
			   (VALUES ('view_project', NULL, true), ('view_work_packages', 'work_package_tracking', false)) AS permission_module_map(permission, project_module, public)
			   LEFT JOIN enabled_modules
			   ON enabled_modules.name = permission_module_map.project_module
			   WHERE permission_module_map.project_module IS NULL OR enabled_modules.project_id IS NOT NULL
			) permission_module_map,
           (
		     SELECT roles.*, role_permissions.permission from roles LEFT JOIN role_permissions ON roles.id = role_permissions.role_id
			   WHERE roles.builtin IN (#{Role::BUILTIN_NON_MEMBER}, #{Role::BUILTIN_ANONYMOUS})
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
         (non_members.project_id = permissions_in_project.project_id OR permissions_in_project.project_id IS NULL)
         AND
         non_members.role_id = permissions_in_project.role_id
    SQL

    add_index :permissions, [:user_id, :project_id, :permission], unique: true
    add_index :permissions, :user_id
    add_index :permissions, :project_id
    add_index :permissions, :permission
  end


#  UNION
#
#  -- In public projects, the anonymous user has permissions
#
#  SELECT DISTINCT
#  users.id,
#    projects.id,
#    permission_module_map.permission
#  FROM
#  users, projects, roles, enabled_modules, role_permissions,
#  (VALUES ('view_project', NULL, true), ('view_work_packages', 'work_package_tracking', false)) AS permission_module_map(permission, project_module, public)
#  WHERE
#  (
#    (roles.id = role_permissions.role_id AND permission_module_map.public = FALSE AND role_permissions.permission = permission_module_map.permission)
#    OR
#    (permission_module_map.public = TRUE)
#  )
#  AND
#  projects.id = enabled_modules.project_id
#  AND
#  (enabled_modules.name = permission_module_map.project_module OR permission_module_map.project_module IS NULL)
#  AND
#  projects.public = TRUE
#  AND
#  users.type IN ('AnonymousUser')
#  AND
#  roles.builtin = #{Role::BUILTIN_ANONYMOUS}
    def down
      execute <<~SQL
      DROP MATERIALIZED VIEW permissions
      SQL
    end
end

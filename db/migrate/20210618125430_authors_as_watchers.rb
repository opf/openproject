class AuthorsAsWatchers < ActiveRecord::Migration[6.1]
  def up
    # Add a watcher on every work package for its author
    # if:
    #   * the author isn't already watcher
    #   * the author isn't locked and has the permission to see the work package
    #     * member of the project in a role with the necessary permission OR
    #     * non member in a public project and the non member role has the necessary permission
    execute <<~SQL
      INSERT INTO watchers (
        watchable_id,
        watchable_type,
        user_id
      )
      SELECT DISTINCT work_packages.id, 'WorkPackage', users.id
      FROM work_packages
      LEFT JOIN
        watchers
        ON watchers.watchable_id = work_packages.id
        AND watchers.watchable_type = 'WorkPackage'
        AND watchers.user_id = work_packages.author_id
      LEFT JOIN
        users
        ON work_packages.author_id = users.id
        AND users.type = 'User'
        AND users.status != #{Principal.statuses[:locked]}
      LEFT JOIN
        projects
        ON work_packages.project_id = projects.id
      LEFT JOIN
        members
        ON work_packages.project_id = members.project_id
        AND members.user_id = users.id
      LEFT JOIN
        member_roles
        ON members.id = member_roles.member_id
      LEFT JOIN
        roles
        ON member_roles.role_id = roles.id
        OR (roles.builtin = #{Role::BUILTIN_NON_MEMBER} AND projects.public)
      LEFT JOIN
        role_permissions
        ON roles.id = role_permissions.role_id
        AND role_permissions.permission = 'view_work_packages'
      WHERE watchers.id IS NULL
      AND users.id IS NOT NULL
      AND role_permissions IS NOT NULL
    SQL
  end

  # No down since we cannot distinguish between watchers that existed before
  # and the ones that where created by the migration.
end

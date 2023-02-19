class MigrateTeamPlannerPermissions < ActiveRecord::Migration[6.1]
  def up
    # Add view_team_planner role if a role already has the view_work_packages permission
    execute <<~SQL.squish
      INSERT INTO
        role_permissions
        (role_id, permission, created_at, updated_at)
      SELECT
        role_permissions.role_id, 'view_team_planner', NOW(), NOW()
      FROM
        role_permissions
      GROUP BY role_permissions.role_id
      HAVING
        ARRAY_AGG(role_permissions.permission)::text[] @> ARRAY['view_work_packages']
      AND
        NOT ARRAY_AGG(role_permissions.permission)::text[] @> ARRAY['view_team_planner'];
    SQL

    # Add manage_team_planner if a role already has
    # the view_team_planner (which in turn means the view_work_packages permission),
    # add_work_packages, edit_work_packages, save_queries and manage_public_queries permission
    execute <<~SQL.squish
      INSERT INTO
        role_permissions
        (role_id, permission, created_at, updated_at)
      SELECT
        role_permissions.role_id, 'manage_team_planner', NOW(), NOW()
      FROM
        role_permissions
      GROUP BY role_permissions.role_id
      HAVING
        ARRAY_AGG(role_permissions.permission)::text[] @>
        ARRAY['view_work_packages', 'add_work_packages', 'edit_work_packages', 'save_queries', 'manage_public_queries']
      AND
        NOT ARRAY_AGG(role_permissions.permission)::text[] @> ARRAY['manage_team_planner']
    SQL
  end

  def down
    # Nothing to do
  end
end

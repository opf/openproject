class AssignableToPermission < ActiveRecord::Migration[6.1]
  def up
    # Because of a missing dependent: :destroy, some role_permission
    # for removed roles exist.
    execute <<~SQL.squish
      DELETE FROM role_permissions WHERE role_id IS NULL
    SQL

    execute <<~SQL.squish
      INSERT INTO role_permissions (role_id, permission, created_at, updated_at)
      SELECT id role_id, 'work_package_assigned' permission, NOW() created_at, NOW() updated_at FROM roles
      WHERE assignable AND type = 'Role' AND builtin = 0
    SQL

    remove_column :roles, :assignable
  end

  def down
    add_column :roles, :assignable, :boolean, default: true

    execute <<~SQL.squish
      UPDATE roles
      SET assignable = EXISTS(SELECT 1 from role_permissions WHERE permission = 'work_package_assigned' and role_id = roles.id)
    SQL

    execute <<~SQL.squish
      DELETE FROM role_permissions where permission = 'work_package_assigned'
    SQL
  end
end

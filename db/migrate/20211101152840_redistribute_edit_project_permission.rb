class RedistributeEditProjectPermission < ActiveRecord::Migration[6.1]
  def up
    add_permission('select_custom_fields')
    add_permission('select_done_status')
  end

  def down
    remove_permission('select_custom_fields')
    remove_permission('select_done_status')
  end

  private

  def add_permission(name)
    execute <<~SQL.squish
      INSERT INTO
      role_permissions
      (permission, role_id, created_at, updated_at)
      SELECT '#{name}', role_id, NOW(), NOW()
      FROM role_permissions
      WHERE permission = 'edit_project'
    SQL
  end

  def remove_permission(name)
    execute <<~SQL.squish
      DELETE FROM
      role_permissions
      WHERE permission = '#{name}'
    SQL
  end
end

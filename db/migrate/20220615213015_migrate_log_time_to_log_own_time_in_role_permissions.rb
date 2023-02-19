class MigrateLogTimeToLogOwnTimeInRolePermissions < ActiveRecord::Migration[7.0]
  def change
    RolePermission.where(permission: 'log_time').update_all(permission: 'log_own_time')
  end
end

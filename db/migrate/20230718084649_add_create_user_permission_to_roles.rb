class AddCreateUserPermissionToRoles < ActiveRecord::Migration[7.0]
  class MigrationRolePermission < ApplicationRecord
    self.table_name = "role_permissions"
  end

  def up
    role_ids = MigrationRolePermission.where(permission: "manage_user").pluck(:role_id)

    role_ids.each do |role_id|
      MigrationRolePermission.create(permission: "create_user", role_id:)
    end
  end

  def down
    MigrationRolePermission.where(permission: "create_user").delete_all
  end
end

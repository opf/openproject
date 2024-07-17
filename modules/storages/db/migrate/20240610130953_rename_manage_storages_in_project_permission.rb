class RenameManageStoragesInProjectPermission < ActiveRecord::Migration[7.1]
  def change
    RolePermission.where(permission: "manage_storages_in_project").update_all(permission: "manage_files_in_project")
  end
end

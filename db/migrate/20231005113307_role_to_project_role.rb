class RoleToProjectRole < ActiveRecord::Migration[7.0]
  def up
    rename_role("Role", "ProjectRole")
  end

  def down
    rename_role("ProjectRole", "Role")
  end

  private

  def rename_role(from, to)
    Role
      .where(type: from)
      .update_all(type: to)
  end
end

class SetManageBoardPermission < ActiveRecord::Migration[5.2]
  def up
    Role
      .joins(:role_permissions)
      .where("role_permissions.permission = 'manage_public_queries'")
      .references(:role_permissions)
      .find_each do |role|

      role.add_permission! :manage_board_views
    end
  end

  def down
    # Nothing to do
  end
end

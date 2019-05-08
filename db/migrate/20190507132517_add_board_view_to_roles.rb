class AddBoardViewToRoles < ActiveRecord::Migration[5.2]
  def up
    Role
      .joins(:role_permissions)
      .where("role_permissions.permission = 'view_work_packages'")
      .references(:role_permissions)
      .find_each do |role|

      role.add_permission! :show_board_views
    end

    unless Setting.default_projects_modules.include?('board_view')
      Setting.default_projects_modules = Setting.default_projects_modules + ['board_view']
    end
  end

  def down
    # Nothing to do
  end
end

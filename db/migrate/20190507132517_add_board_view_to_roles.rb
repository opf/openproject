require "#{Rails.root}/db/migrate/migration_utils/permission_adder"

class AddBoardViewToRoles < ActiveRecord::Migration[5.2]
  def up
    ::Migration::MigrationUtils::PermissionAdder
      .add(:view_work_packages,
           :show_board_views)

    unless Setting.default_projects_modules.include?('board_view')
      Setting.default_projects_modules = Setting.default_projects_modules + ['board_view']
    end
  end

  def down
    # Nothing to do
  end
end

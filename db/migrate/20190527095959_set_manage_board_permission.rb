require "#{Rails.root}/db/migrate/migration_utils/permission_adder"

class SetManageBoardPermission < ActiveRecord::Migration[5.2]
  def up
    ::Migration::MigrationUtils::PermissionAdder
      .add(:manage_public_queries,
           :manage_board_views)
  end

  def down
    # Nothing to do
  end
end

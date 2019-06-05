require "#{Rails.root}/db/migrate/migration_utils/permission_adder"

class SetAssignVersionsPermission < ActiveRecord::Migration[5.2]
  def up
    ::Migration::MigrationUtils::PermissionAdder
      .add(:edit_work_packages,
           :assign_versions)
  end

  def down
    # nothing to do
  end
end

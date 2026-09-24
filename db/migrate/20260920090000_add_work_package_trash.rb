# frozen_string_literal: true

require Rails.root.join("db/migrate/migration_utils/permission_adder")

class AddWorkPackageTrash < ActiveRecord::Migration[8.0]
  def up
    change_table :work_packages, bulk: true do |t|
      t.datetime :deleted_at
      t.bigint :deleted_by_id
      t.uuid :deletion_group
    end

    add_index :work_packages, :deleted_at
    add_index :work_packages, :deletion_group
    add_foreign_key :work_packages, :users, column: :deleted_by_id, on_delete: :nullify

    change_table :work_package_journals, bulk: true do |t|
      t.datetime :deleted_at
      t.bigint :deleted_by_id
    end

    ::Migration::MigrationUtils::PermissionAdder.add(:delete_work_packages, :manage_work_package_trash)
    ::Migration::MigrationUtils::PermissionAdder.add(:delete_work_packages, :view_work_packages_in_trash)
  end

  def down
    RolePermission.delete_by(permission: %w[manage_work_package_trash view_work_packages_in_trash])

    remove_column :work_package_journals, :deleted_by_id
    remove_column :work_package_journals, :deleted_at

    remove_foreign_key :work_packages, column: :deleted_by_id
    remove_column :work_packages, :deletion_group
    remove_column :work_packages, :deleted_by_id
    remove_column :work_packages, :deleted_at
  end
end

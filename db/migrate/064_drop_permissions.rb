class DropPermissions < ActiveRecord::Migration
  def self.up
    drop_table :permissions
    drop_table :permissions_roles
  end

  def self.down
    raise IrreversibleMigration
  end
end

class DropMembersRoleId < ActiveRecord::Migration
  def self.up
    remove_column :members, :role_id
  end

  def self.down
    raise IrreversibleMigration
  end
end

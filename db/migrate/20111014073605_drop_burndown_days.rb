class DropBurndownDays < ActiveRecord::Migration
  def self.up
    drop_table :burndown_days
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

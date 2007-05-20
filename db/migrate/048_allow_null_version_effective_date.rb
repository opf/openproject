class AllowNullVersionEffectiveDate < ActiveRecord::Migration
  def self.up
    change_column :versions, :effective_date, :date, :default => nil
  end

  def self.down
    raise IrreversibleMigration
  end
end

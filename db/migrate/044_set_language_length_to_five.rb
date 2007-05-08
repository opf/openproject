class SetLanguageLengthToFive < ActiveRecord::Migration
  def self.up
    change_column :users, :language, :string, :limit => 5, :default => ""
  end

  def self.down
    raise IrreversibleMigration
  end
end

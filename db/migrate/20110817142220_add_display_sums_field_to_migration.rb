class AddDisplaySumsFieldToMigration < ActiveRecord::Migration
  def self.up
    add_column :queries, :display_sums, :boolean, :null => true
  end

  def self.down
    remove_column :queries, :display_sums
  end
end

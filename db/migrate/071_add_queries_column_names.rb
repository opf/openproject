class AddQueriesColumnNames < ActiveRecord::Migration
  def self.up
    add_column :queries, :column_names, :text
  end

  def self.down
    remove_column :queries, :column_names
  end
end

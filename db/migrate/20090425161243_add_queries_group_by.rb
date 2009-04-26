class AddQueriesGroupBy < ActiveRecord::Migration
  def self.up
    add_column :queries, :group_by, :string
  end

  def self.down
    remove_column :queries, :group_by
  end
end

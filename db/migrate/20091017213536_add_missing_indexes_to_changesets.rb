class AddMissingIndexesToChangesets < ActiveRecord::Migration
  def self.up
    add_index :changesets, :user_id
    add_index :changesets, :repository_id
  end

  def self.down
    remove_index :changesets, :user_id
    remove_index :changesets, :repository_id
  end
end

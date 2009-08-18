class AddPointsToItems < ActiveRecord::Migration
  def self.up
    add_column :items, :points, :integer, :default => 0
  end

  def self.down
    remove_column :items, :points
  end
end

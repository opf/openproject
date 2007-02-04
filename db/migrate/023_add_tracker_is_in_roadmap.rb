class AddTrackerIsInRoadmap < ActiveRecord::Migration
  def self.up
    add_column :trackers, :is_in_roadmap, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :trackers, :is_in_roadmap
  end
end

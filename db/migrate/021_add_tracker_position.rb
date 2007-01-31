class AddTrackerPosition < ActiveRecord::Migration
  def self.up
    add_column :trackers, :position, :integer, :default => 1, :null => false
    Tracker.find(:all).each_with_index {|tracker, i| tracker.update_attribute(:position, i+1)}
  end

  def self.down
    remove_column :trackers, :position
  end
end

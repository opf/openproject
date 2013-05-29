class AddDeletedAtToTimelinesPlanningElements < ActiveRecord::Migration
  def self.up
    add_column :planning_elements, :deleted_at, :datetime
  end

  def self.down
    remove_column :planning_elements, :deleted_at
  end
end

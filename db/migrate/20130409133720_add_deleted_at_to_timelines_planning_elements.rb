class AddDeletedAtToTimelinesPlanningElements < ActiveRecord::Migration
  def self.up
    add_column :timelines_planning_elements, :deleted_at, :datetime
  end

  def self.down
    remove_column :timelines_planning_elements, :deleted_at
  end
end

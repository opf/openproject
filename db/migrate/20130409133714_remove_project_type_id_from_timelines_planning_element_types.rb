class RemoveProjectTypeIdFromTimelinesPlanningElementTypes < ActiveRecord::Migration
  def self.up
    change_table(:timelines_planning_element_types) do |t|
      t.remove :project_type_id
    end
  end

  def self.down
    change_table(:timelines_planning_element_types) do |t|
      t.belongs_to :project_type
    end
    add_index :timelines_planning_element_types, :project_type_id
  end
end

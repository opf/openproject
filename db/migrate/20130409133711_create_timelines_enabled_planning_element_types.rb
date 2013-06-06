class CreateTimelinesEnabledPlanningElementTypes < ActiveRecord::Migration
  def self.up
    create_table :timelines_enabled_planning_element_types do |t|
      t.belongs_to :project
      t.belongs_to :planning_element_type

      t.timestamps
    end

    add_index :timelines_enabled_planning_element_types, :project_id
    add_index :timelines_enabled_planning_element_types, :planning_element_type_id, :name => "index_enabled_planning_element_types_on_planning_element_type_id"
  end

  def self.down
    drop_table :timelines_enabled_planning_element_types
  end
end

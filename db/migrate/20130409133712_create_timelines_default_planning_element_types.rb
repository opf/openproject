class CreateTimelinesDefaultPlanningElementTypes < ActiveRecord::Migration
  def self.up
    create_table :timelines_default_planning_element_types do |t|
      t.belongs_to :project_type
      t.belongs_to :planning_element_type

      t.timestamps
    end

    add_index :timelines_default_planning_element_types, :project_type_id, :name => "index_default_planning_element_types_on_project_type_id"
    add_index :timelines_default_planning_element_types, :planning_element_type_id, :name => "index_default_planning_element_types_on_planning_element_type_id"

  end

  def self.down
    drop_table :timelines_default_planning_element_types
  end
end

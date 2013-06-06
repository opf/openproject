class CreateTimelinesPlanningElementTypes < ActiveRecord::Migration
  def self.up
    create_table(:timelines_planning_element_types) do |t|
      t.column :name,         :string,  :null => false

      t.column :in_aggregation, :boolean, :default => true,  :null => false
      t.column :is_milestone,   :boolean, :default => false, :null => false
      t.column :is_default,     :boolean, :default => false, :null => false

      t.column :position,     :integer, :default => 1,     :null => false

      t.belongs_to :color
      t.belongs_to :project_type

      t.timestamps
    end

    add_index :timelines_planning_element_types, :color_id
    add_index :timelines_planning_element_types, :project_type_id
  end

  def self.down
    drop_table(:timelines_planning_element_types)
  end
end

class CreateTimelinesScenarios < ActiveRecord::Migration
  def self.up
    create_table(:timelines_scenarios) do |t|
      t.column :name,        :string, :null => false
      t.column :description, :text

      t.belongs_to :project

      t.timestamps
    end

    add_index :timelines_scenarios, :project_id
  end

  def self.down
    drop_table(:timelines_scenarios)
  end
end

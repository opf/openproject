class CreateTimelinesScenarios < ActiveRecord::Migration
  def self.up
    create_table(:scenarios) do |t|
      t.column :name,        :string, :null => false
      t.column :description, :text

      t.belongs_to :project

      t.timestamps
    end

    add_index :scenarios, :project_id
  end

  def self.down
    drop_table(:scenarios)
  end
end

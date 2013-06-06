class CreateTimelinesProjectAssociations < ActiveRecord::Migration
  def self.up
    create_table(:timelines_project_associations) do |t|
      t.belongs_to :project_a
      t.belongs_to :project_b

      t.column :description, :text

      t.timestamps
    end

    add_index :timelines_project_associations, :project_a_id
    add_index :timelines_project_associations, :project_b_id
  end

  def self.down
    drop_table :timelines_project_associations
  end
end

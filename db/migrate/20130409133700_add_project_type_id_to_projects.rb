class AddTimelinesProjectTypeIdToProjects < ActiveRecord::Migration
  def self.up
    change_table(:projects) do |t|
      t.belongs_to :project_type

      t.index :project_type_id
    end
  end

  def self.down
    change_table(:projects) do |t|
      t.remove_belongs_to :project_type
    end
  end
end

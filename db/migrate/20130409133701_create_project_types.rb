class CreateTimelinesProjectTypes < ActiveRecord::Migration
  def self.up
    create_table(:project_types) do |t|
      t.column :name,               :string,  :default => '',   :null => false
      t.column :allows_association, :boolean, :default => true, :null => false
      t.column :position,           :integer, :default => 1,    :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :project_types
  end
end

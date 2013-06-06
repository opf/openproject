class CreateTimelinesTimelines < ActiveRecord::Migration
  def self.up
    create_table :timelines_timelines do |t|
      t.column :name,        :string,  :null => false
      t.column :content,     :text

      t.belongs_to :project

      t.timestamps
    end

    add_index :timelines_timelines, :project_id
  end

  def self.down
    drop_table :timelines_timelines
  end
end

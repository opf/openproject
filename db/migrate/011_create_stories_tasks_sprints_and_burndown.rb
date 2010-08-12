class CreateStoriesTasksSprintsAndBurndown < ActiveRecord::Migration
  def self.up
    add_column :issues, :position, :integer
    add_column :issues, :story_points, :integer
    add_column :issues, :remaining_hours, :float

    add_column :versions, :sprint_start_date, :date, :null => true

    create_table :burndown_days do |t|
      t.column :points_committed, :integer, :null => false, :default => 0
      t.column :points_accepted, :integer, :null => false, :default => 0
      t.column :points_resolved, :integer, :null => false, :default => 0
      t.column :remaining_hours, :float, :null => false, :default => 0

      t.column :version_id, :integer, :null => false
      t.timestamps
    end

    add_index :burndown_days, :version_id

    # RM core started needing this... I'm not agreeing, but I need to
    # get the migration working
    execute "update issues set start_date = NULL where due_date < start_date"
  end

  def self.down
    drop_column :issues, :position
    drop_column :issues, :story_points
    drop_column :issues, :remaining_hours

    drop_column :versions, :sprint_start_date

    drop_index :burndown_days, :version_id
    drop_table :burndown_days
  end
end

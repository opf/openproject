class AddBacklogColumnsToWorkPackageJournal < ActiveRecord::Migration
  def change
    add_column :work_package_journals, :story_points, :integer
    add_column :work_package_journals, :remaining_hours, :float
  end
end

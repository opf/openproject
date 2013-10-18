class AddBacklogsColumnToWorkPackage < ActiveRecord::Migration
  def change
    add_column :work_packages, :position, :integer
    add_column :work_packages, :story_points, :integer
    add_column :work_packages, :remaining_hours, :float
    WorkPackage.reset_column_information
  end
end

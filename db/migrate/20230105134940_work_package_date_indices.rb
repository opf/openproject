class WorkPackageDateIndices < ActiveRecord::Migration[7.0]
  def change
    add_index :work_packages, :start_date
    add_index :work_packages, :due_date
  end
end

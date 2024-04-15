class AddIndicesToWorkPackageJournals < ActiveRecord::Migration[7.0]
  def change
    add_index :work_package_journals, :assigned_to_id
    add_index :work_package_journals, :author_id
    add_index :work_package_journals, :category_id
    add_index :work_package_journals, :parent_id
    add_index :work_package_journals, :responsible_id
    add_index :work_package_journals, :status_id
    add_index :work_package_journals, :type_id
    add_index :work_package_journals, :version_id

    add_index :work_package_journals, :schedule_manually
    add_index :work_package_journals, :start_date
    add_index :work_package_journals, :due_date
  end
end

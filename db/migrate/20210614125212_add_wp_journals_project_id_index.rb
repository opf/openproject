class AddWpJournalsProjectIdIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :work_package_journals, :project_id
  end
end

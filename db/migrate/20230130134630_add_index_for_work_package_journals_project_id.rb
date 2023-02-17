class AddIndexForWorkPackageJournalsProjectId < ActiveRecord::Migration[7.0]
  def change
    add_index :news_journals, :project_id
    add_index :time_entry_journals, :project_id
    add_index :work_package_journals, :project_id
  end
end

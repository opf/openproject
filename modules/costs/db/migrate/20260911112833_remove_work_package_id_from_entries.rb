# frozen_string_literal: true

class RemoveWorkPackageIdFromEntries < ActiveRecord::Migration[8.1]
  def change
    remove_index :time_entries, :work_package_id, name: "time_entries_issue_id"

    remove_column :time_entries, :work_package_id, :bigint
    remove_column :time_entry_journals, :work_package_id, :bigint
    remove_column :cost_entries, :work_package_id, :bigint
  end
end

# frozen_string_literal: true

class RemoveWorkPackageIdFromEntries < ActiveRecord::Migration[8.1]
  # The time_entries_issue_id index is dropped implicitly with its column, so it never
  # has to be looked up by name.
  def change
    remove_column :time_entries, :work_package_id, :bigint
    remove_column :time_entry_journals, :work_package_id, :bigint
    remove_column :cost_entries, :work_package_id, :bigint
  end
end

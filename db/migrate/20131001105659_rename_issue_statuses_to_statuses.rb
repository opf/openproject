class RenameIssueStatusesToStatuses < ActiveRecord::Migration
  def change
    rename_table :issue_statuses, :statuses
  end
end

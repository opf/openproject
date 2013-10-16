class RenameIssueStatusToStatus < ActiveRecord::Migration
  def change
    rename_table :issue_done_statuses_for_project, :done_statuses_for_project
    rename_column :done_statuses_for_project, :issue_status_id, :status_id
  end
end

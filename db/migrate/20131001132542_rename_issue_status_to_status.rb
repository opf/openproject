class RenameIssueStatusToStatus < ActiveRecord::Migration
  def initialize
    super
    @issue_done_statuses_for_project_exists = \
      ActiveRecord::Base.connection.tables.include? 'issue_done_statuses_for_project'
  end

  def change
    if @issue_done_statuses_for_project_exists
      rename_table :issue_done_statuses_for_project, :done_statuses_for_project
      rename_column :done_statuses_for_project, :issue_status_id, :status_id
    else
      create_table :done_statuses_for_project, :id => false do |t|
        t.references :project
        t.references :status
      end
    end
  end
end

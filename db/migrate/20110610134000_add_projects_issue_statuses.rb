class AddProjectsIssueStatuses < ActiveRecord::Migration
  def self.up
    create_table :issue_done_statuses_for_project, :id => false do |t|
      t.references :project
      t.references :issue_status
    end
  end

  def self.down
    drop_table :issue_done_statuses_for_project
  end
end

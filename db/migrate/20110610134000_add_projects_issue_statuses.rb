class AddProjectsIssueStatuses < ActiveRecord::Migration
  def initialize
    super
    @issue_statuses_exists = ActiveRecord::Base.connection.tables.include? 'issue_statuses'
  end

  def self.up
    if @issue_statuses_exists
      create_table :issue_done_statuses_for_project, :id => false do |t|
        t.references :project
        t.references :issue_status
      end
    end
  end

  def self.down
    if @issue_statuses_exists
      drop_table :issue_done_statuses_for_project
    end
  end
end

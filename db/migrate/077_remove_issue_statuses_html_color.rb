class RemoveIssueStatusesHtmlColor < ActiveRecord::Migration
  def self.up
    remove_column :issue_statuses, :html_color
  end

  def self.down
    raise IrreversibleMigration
  end
end

class AddDefaultDoneRatioToIssueStatus < ActiveRecord::Migration
  def self.up
    add_column :issue_statuses, :default_done_ratio, :integer
  end

  def self.down
    remove_column :issue_statuses, :default_done_ratio
  end
end

class AddIssueStatusPosition < ActiveRecord::Migration
  def self.up
    add_column :issue_statuses, :position, :integer, :default => 1
    IssueStatus.find(:all).each_with_index {|status, i| status.update_attribute(:position, i+1)}
  end

  def self.down
    remove_column :issue_statuses, :position
  end
end

class CreateBacklogItemsFromIssue < ActiveRecord::Migration
  def self.up
    Version.transaction do
      Version.find(:all).each { |version| Backlog.update_from_version(version) }
      Issue.find(:all).each { |issue| Item.update_from_issue(issue) }
    end
  end

  def self.down
  end
end

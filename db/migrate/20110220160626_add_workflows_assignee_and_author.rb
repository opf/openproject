class AddWorkflowsAssigneeAndAuthor < ActiveRecord::Migration
  def self.up
    add_column :workflows, :assignee, :boolean, :null => false, :default => false
    add_column :workflows, :author, :boolean, :null => false, :default => false
    Workflow.update_all("assignee = #{Workflow.connection.quoted_false}")
    Workflow.update_all("author = #{Workflow.connection.quoted_false}")
  end

  def self.down
    remove_column :workflows, :assignee
    remove_column :workflows, :author
  end
end

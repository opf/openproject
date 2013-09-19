class RenameIssueRelationsFromToColumns < ActiveRecord::Migration
  def change
    rename_column :issue_relations, :issue_from_id, :from_id
    rename_column :issue_relations, :issue_to_id, :to_id
  end
end

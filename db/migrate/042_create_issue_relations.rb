class CreateIssueRelations < ActiveRecord::Migration
  def self.up
    create_table :issue_relations do |t|
      t.column :issue_from_id, :integer, :null => false
      t.column :issue_to_id, :integer, :null => false
      t.column :relation_type, :string, :default => "", :null => false
      t.column :delay, :integer
    end
  end

  def self.down
    drop_table :issue_relations
  end
end

class CreateBacklogItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.column :issue_id, :integer, :null => false
      t.column :backlog_id, :integer, :null => true
      t.column :position, :integer
      t.timestamps
    end
    
    add_index :items, :issue_id
    add_index :items, :backlog_id
  end

  def self.down
    drop_table :items
  end
end

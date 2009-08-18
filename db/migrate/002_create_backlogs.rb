class CreateBacklogs < ActiveRecord::Migration
  def self.up
    create_table :backlogs do |t|
      t.column :version_id, :integer, :null => false
      t.column :start_date, :datetime, :null => true
      t.column :is_closed, :boolean, :default => false
      t.timestamps
    end
    
    add_index :backlogs, :version_id
  end

  def self.down
    drop_table :backlogs
  end
end

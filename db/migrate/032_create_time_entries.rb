class CreateTimeEntries < ActiveRecord::Migration
  def self.up
    create_table :time_entries do |t|
      t.column :project_id,  :integer,  :null => false
      t.column :user_id,     :integer,  :null => false
      t.column :issue_id,    :integer
      t.column :hours,       :float,    :null => false
      t.column :comment,     :string,   :limit => 255
      t.column :activity_id, :integer,  :null => false
      t.column :spent_on,    :date,     :null => false
      t.column :tyear,       :integer,  :null => false
      t.column :tmonth,      :integer,  :null => false
      t.column :tweek,       :integer,  :null => false
      t.column :created_on,  :datetime, :null => false
      t.column :updated_on,  :datetime, :null => false
    end
    add_index :time_entries, [:project_id], :name => :time_entries_project_id
    add_index :time_entries, [:issue_id], :name => :time_entries_issue_id
  end

  def self.down
    drop_table :time_entries
  end
end

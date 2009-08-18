class CreateChartData < ActiveRecord::Migration
  def self.up
    create_table :backlog_chart_data do |t|
      t.column :scope, :integer, :default => 0, :null => false
      t.column :done,  :integer, :default => 0, :null => false
      t.column :wip,   :integer, :default => 0, :null => false
      t.column :backlog_id, :integer
      t.timestamps
    end
    add_index :backlog_chart_data, :backlog_id
  end
  
  def self.down
    drop_table :backlog_chart_data
  end
end

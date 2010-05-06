class CreateCostQueries < ActiveRecord::Migration
  def self.up
    create_table :cost_queries do |t|
      t.references :user, :null => false
      t.references :project
      
      t.column :name, :string, :limit => 255, :null => false
      t.column :filters, :text
      t.column :group_by, :text
      t.column :granularity, :string
      t.column :is_public, :boolean, :default => false, :null => false

      t.column :created_on,               :timestamp, :null => false
      t.column :updated_on,               :timestamp, :null => false
    end
  end

  def self.down
    drop_table :cost_queries
  end
end

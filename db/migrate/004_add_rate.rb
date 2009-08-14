class AddRate < ActiveRecord::Migration
  def self.up
    create_table :rates do |t|
      t.column :valid_from,               :date,    :null => false
      t.column :rate,                     :decimal, :precision => 15, :scale => 2, :null => false
      t.column :type,                     :string,  :limit => 255, :null => false
      
      # for HourlyRate
      t.column :project_id,               :integer
      t.column :user_id,                  :integer

      # for CostRate
      t.column :cost_type_id,             :integer
    end
    
    ## Refactor cost_types table
    # Remove colums for storing of rates
    # This info is stored in the rate table
    remove_column :cost_types, :unit_price
    remove_column :cost_types, :valid_from
  end
  
  def self.down
    drop_table :rates
    
    t.column :unit_price,               :decimal, :precission => 15, :scale => 2, :null => false
    t.column :valid_from,               :date,    :null => false
  end
end

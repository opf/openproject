class CreateDeliverables < ActiveRecord::Migration
  def self.up
    create_table :deliverables do |t|
      t.column :project_id,               :integer, :null => false
      t.column :author_id,                :integer, :null => false
      t.column :project_id,               :integer, :null => false
      t.column :subject,                  :string,  :null => false
      t.column :description,              :text,    :null => false
      t.column :type,                     :string,  :limit => 255, :null => false
      t.column :project_manager_signoff,  :boolean, :default => false, :null => false
      t.column :client_signoff,           :boolean, :default => false, :null => false
      
      t.column :budget,                   :decimal, :precision => 15, :scale => 2, :null => false
      t.column :fixed_date,               :date,    :null => false
    end
    
    create_table :deliverable_costs do |t|
      t.column :deliverable_id,           :integer, :null => false
      t.column :rate_id,                  :integer, :null => false
      t.column :units,                    :float,   :null => false
    end
    
    create_table :deliverable_hours do |t|
      t.column :deliverable_id,           :integer, :null => false
      t.column :rate_id,                  :integer, :null => false
      t.column :hours,                    :float,   :null => false
    end
    
    create_table :cost_types do |t|
      t.column :name,                     :string,  :limit => 255, :null => false
      t.column :unit,                     :string,  :limit => 255, :null => false
      t.column :unit_plural,              :string,  :limit => 255, :null => false
      t.column :unit_price,               :decimal, :precission => 15, :scale => 2, :null => false
      t.column :valid_from,               :date,    :null => false
    end
    
    create_table :cost_entries do |t|
      t.column :user_id,                  :integer, :null => false
      t.column :project_id,               :integer, :null => false
      t.column :issue_id,                 :integer, :null => false
      t.column :cost_type_id,             :integer, :null => false
      t.column :units,                    :float,   :null => false
      t.column :cost,                     :decimal, :precission => 15, :scale => 2, :null => false
      t.column :spent_on,                 :date,    :null => false
      t.column :created_on,               :timestamp, :null => false
      t.column :updated_on,               :timestamp, :null => false
      t.column :comments,                 :string,  :limit => 255, :null => false
      t.column :blocked,                  :boolean, :default => false, :null => false
    end
  end
  
  def self.down
    drop_table :deliverables
    drop_table :deliverable_costs
    drop_table :deliverable_hours
    drop_table :cost_types
    drop_table :cost_entries 
  end
end

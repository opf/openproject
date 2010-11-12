class AddDeliverablesDateFields < ActiveRecord::Migration
  def self.up
    add_column :deliverables, :created_on, :timestamp#,    :null => false
    add_column :deliverables, :updated_on, :timestamp#,    :null => false
  end
  
  def self.down
    remove_column :deliverables, :created_on
    remove_column :deliverables, :updated_on
  end
end
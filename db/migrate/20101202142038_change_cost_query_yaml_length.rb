class ChangeCostQueryYamlLength < ActiveRecord::Migration
  def self.up
    change_column :cost_queries, :yamlized, :string, :limit => 2000, :null => false
  end

  def self.down
    change_column :cost_queries, :yamlized, :string, :length => 255, :null => false
  end
end

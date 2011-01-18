class RenameYamlizedToSerialized < ActiveRecord::Migration
  def self.up
    rename_column :cost_queries, :yamlized, :serialized
  end

  def self.down
    rename_column :cost_queries, :serialized, :yamlized
  end
end

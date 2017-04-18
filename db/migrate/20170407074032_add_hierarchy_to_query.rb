class AddHierarchyToQuery < ActiveRecord::Migration[5.0]
  def change
    add_column :queries, :show_hierarchies, :boolean, default: false
  end
end

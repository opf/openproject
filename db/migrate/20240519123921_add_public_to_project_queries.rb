class AddPublicToProjectQueries < ActiveRecord::Migration[7.1]
  def change
    add_column :project_queries, :public, :boolean, default: false, null: false
    add_index :project_queries, :public
  end
end

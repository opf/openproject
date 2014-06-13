class AddShownInAllProjectsToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :shown_in_all_projects, :boolean, :null => false, :default => false
  end
end

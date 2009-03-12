class AddQueriesSortCriteria < ActiveRecord::Migration
  def self.up
    add_column :queries, :sort_criteria, :text
  end

  def self.down
    remove_column :queries, :sort_criteria
  end
end

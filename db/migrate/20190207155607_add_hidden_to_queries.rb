class AddHiddenToQueries < ActiveRecord::Migration[5.2]
  def change
    add_column :queries, :hidden, :boolean, default: false
  end
end

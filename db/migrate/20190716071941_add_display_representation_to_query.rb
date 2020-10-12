class AddDisplayRepresentationToQuery < ActiveRecord::Migration[5.2]
  def change
    add_column :queries, :display_representation, :text
  end
end

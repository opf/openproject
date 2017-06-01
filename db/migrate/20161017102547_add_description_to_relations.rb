class AddDescriptionToRelations < ActiveRecord::Migration[5.0]
  def change
    add_column :relations, :description, :text
  end
end

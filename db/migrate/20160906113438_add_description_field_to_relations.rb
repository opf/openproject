class AddDescriptionFieldToRelations < ActiveRecord::Migration
  def change
    add_column :relations, :description, :string, null: true
  end
end

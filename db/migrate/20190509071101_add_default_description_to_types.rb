class AddDefaultDescriptionToTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :types, :description, :text
  end
end

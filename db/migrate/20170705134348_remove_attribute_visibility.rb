class RemoveAttributeVisibility < ActiveRecord::Migration[5.0]
  def change
    remove_column :types, :attribute_visibility, :text
  end
end

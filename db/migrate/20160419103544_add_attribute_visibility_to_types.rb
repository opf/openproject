class AddAttributeVisibilityToTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :types, :attribute_visibility, :text, hash: true
  end
end

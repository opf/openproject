class AddAttributeVisibilityToTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :types, :attribute_visibility, :text, hash: true
  end
end

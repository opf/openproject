class AddAttributeVisibilityToTypes < ActiveRecord::Migration
  def change
    add_column :types, :attribute_visibility, :text, hash: true
  end
end

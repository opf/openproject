class AddAttributeVisibilityToTypes < ActiveRecord::Migration
  def change
    add_column :types, :attribute_visibility, :text, hash: true, default: {}
  end
end

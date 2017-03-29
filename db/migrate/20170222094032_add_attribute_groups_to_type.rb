class AddAttributeGroupsToType < ActiveRecord::Migration[5.0]
  def change
    add_column :types, :attribute_groups, :text
  end
end

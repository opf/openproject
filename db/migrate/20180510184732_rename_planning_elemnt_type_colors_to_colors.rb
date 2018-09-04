class RenamePlanningElemntTypeColorsToColors < ActiveRecord::Migration[5.1]
  def up
    rename_table :planning_element_type_colors, :colors
    remove_column :colors, :position
  end

  def down
    rename_table :colors, :planning_element_type_colors

    change_table :planning_element_type_colors do
      t.integer :position, default: 1, null: true
    end
  end
end

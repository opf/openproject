class RenamePlanningElemntTypeColorsToColors < ActiveRecord::Migration[5.1]
  def up

    # Fix existing indexes due to old migration away from timeline_colors
    if table_exists? :timelines_colors_pkey
      rename_table :timelines_colors_pkey, :planning_element_type_colors_pkey
    end

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

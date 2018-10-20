class RenamePlanningElemntTypeColorsToColors < ActiveRecord::Migration[5.1]
  def up
    # Fix existing indexes due to old migration away from timeline_colors
    # This hasn't happened automatically in Rails < 4 with the 2013 migration of timelines_colors
    if index_name_exists?(:planning_element_type_colors, :timelines_colors_pkey)
      rename_index :planning_element_type_colors, :timelines_colors_pkey, :planning_element_type_colors_pkey
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

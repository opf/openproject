class RenamePlanningElemntTypeColorsToColors < ActiveRecord::Migration[5.1]
  def up
    # Fix existing indexes due to old migration away from timeline_colors
    # This hasn't happened automatically in Rails < 4 with the 2013 migration of timelines_colors
    if index_name_exists?(:planning_element_type_colors, :timelines_colors_pkey)
      rename_index :planning_element_type_colors, :timelines_colors_pkey, :planning_element_type_colors_pkey
    end

    if ActiveRecord::Base.connection.execute("SELECT 1 as value FROM pg_class c WHERE c.relkind = 'S' and c.relname = 'planning_element_type_colors_id_seq'").to_a.present?
      puts "Renaming id_seq to pkey which seems to be required by rename_table"
      rename_index :planning_element_type_colors, :planning_element_type_colors_id_seq, :planning_element_type_colors_pkey
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

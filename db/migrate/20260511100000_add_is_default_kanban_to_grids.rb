# frozen_string_literal: true

class AddIsDefaultKanbanToGrids < ActiveRecord::Migration[8.0]
  def change
    add_column :grids, :is_default_kanban, :boolean, default: false, null: false

    # Ensures at most one default kanban board per project
    add_index :grids, :project_id,
              unique: true,
              where: "is_default_kanban = TRUE AND type = 'Boards::Grid'",
              name: "idx_unique_default_kanban_per_project"
  end
end

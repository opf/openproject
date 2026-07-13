# frozen_string_literal: true

class AddLinkedToGrids < ActiveRecord::Migration[8.0]
  def change
    add_reference :grids, :linked, polymorphic: true, index: false
    add_index :grids,
              %i[project_id linked_type linked_id],
              name: "index_grids_on_project_and_linked"
  end
end

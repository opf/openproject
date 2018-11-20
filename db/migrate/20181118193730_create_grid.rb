class CreateGrid < ActiveRecord::Migration[5.1]
  def change
    create_grids
    create_grid_widgets
  end

  private

  def create_grids
    create_table :grids do |t|
      t.integer :row_count, null: false
      t.integer :column_count, null: false
      t.string :type

      t.references :user

      t.timestamps
    end
  end

  def create_grid_widgets
    create_table :grid_widgets do |t|
      t.integer :start_row, null: false
      t.integer :end_row, null: false
      t.integer :start_column, null: false
      t.integer :end_column, null: false
      t.string :identifier
      t.text :options
      t.references :grid
    end
  end
end

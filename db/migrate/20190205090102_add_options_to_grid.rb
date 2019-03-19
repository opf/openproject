class AddOptionsToGrid < ActiveRecord::Migration[5.2]
  def change
    change_table :grids do |t|
      t.text :name
      t.text :options
    end
  end
end

class AddProjectToGrid < ActiveRecord::Migration[5.2]
  def change
    change_table :grids do |t|
      t.references :project
    end
  end
end

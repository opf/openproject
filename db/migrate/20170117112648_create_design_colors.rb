class CreateDesignColors < ActiveRecord::Migration[5.0]
  def change
    create_table :design_colors do |t|
      t.string :variable
      t.string :hexcode

      t.timestamps
    end

    add_index :design_colors, :variable, unique: true
  end
end

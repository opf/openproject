class AddStandardColumnToTypeTable < ActiveRecord::Migration
  def change
    add_column :types, :is_standard, :boolean, null: false, default: false
  end
end

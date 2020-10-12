class AddIsDefaultToIfcModels < ActiveRecord::Migration[5.1]
  def change
    add_column :ifc_models, :is_default, :boolean, default: false, null: false

    add_index :ifc_models, :is_default
  end
end

class AddIfcModelsPlugin < ActiveRecord::Migration[5.1]
  def change
    create_table :ifc_models do |t|
      t.string :title
      t.timestamps

      t.references :project, foreign_key: { on_delete: :cascade }, index: true
      t.references :uploader, index: true
    end
  end
end

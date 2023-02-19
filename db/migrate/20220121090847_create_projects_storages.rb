class CreateProjectsStorages < ActiveRecord::Migration[6.1]
  def change
    create_table :projects_storages do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :storage, null: false, foreign_key: { on_delete: :cascade }
      t.references :creator,
                   null: false,
                   index: true,
                   foreign_key: { to_table: :users }

      t.timestamps

      t.index %i[project_id storage_id], unique: true
    end
  end
end

class CreateProjectsStorages < ActiveRecord::Migration[6.1]
  def change
    create_table :projects_storages do |t|
      t.bigint :project_id, null: false, foreign_key: true
      t.bigint :storage_id, null: false, foreign_key: true
      t.bigint :creator_id, null: false, foreign_key: true

      t.timestamps

      t.index :project_id
      t.index :storage_id
      t.index %i[project_id storage_id], unique: true
    end
  end
end

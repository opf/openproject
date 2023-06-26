class CreatePermissionTable < ActiveRecord::Migration[7.0]
  def change
    create_table :active_permissions, id: false do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, null: true, foreign_key: { on_delete: :cascade }
      t.string :permission, null: false
    end

    add_index :active_permissions,
              %i[user_id project_id permission],
              unique: true,
              name: 'index_active_permissions_on_user_and_project_and_permission'
  end
end

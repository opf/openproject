class AddOptionalEntityToMembers < ActiveRecord::Migration[7.0]
  def change
    add_reference :members, :entity, foreign_key: false, polymorphic: true, index: true
    remove_index :members, %i[user_id project_id], unique: true

    add_index :members, %i[user_id project_id],
              unique: true,
              where: "entity_type IS NULL AND entity_id IS NULL",
              name: "index_members_on_user_id_and_project_without_entity"

    add_index :members, %i[user_id project_id entity_type entity_id],
              unique: true,
              where: "entity_type IS NOT NULL AND entity_id IS NOT NULL",
              name: "index_members_on_user_id_and_project_with_entity"
  end
end

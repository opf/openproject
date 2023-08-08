class AddWorkPackageMembership < ActiveRecord::Migration[7.0]
  def change
    add_belongs_to :members, :entity, polymorphic: true, null: true, index: true
    remove_index :members, %i[user_id project_id], unique: true
    add_index :members, %i[user_id entity_type entity_id], unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE "members" SET "entity_type" = 'Project', "entity_id" = "project_id" WHERE project_id IS NOT NULL
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          UPDATE "members" SET "project_id" = "entity_id" WHERE "entity_type" = 'Project' IS NOT NULL
        SQL
      end
    end

    remove_column :members, :project_id, :int
  end
end

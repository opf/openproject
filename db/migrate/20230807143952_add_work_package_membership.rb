class AddWorkPackageMembership < ActiveRecord::Migration[7.0]
  def change
    add_belongs_to :members, :work_package, foreign_key: true, null: true, index: true
    remove_index :members, %i[user_id project_id], unique: true
    add_index :members, %i[user_id project_id work_package_id], unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          ALTER TABLE members ADD CONSTRAINT either_member_of_work_package_or_project
            CHECK (num_nulls(work_package_id, project_id) >= 1)
        SQL
      end

      dir.down do
        execute 'ALTER TABLE members DROP CONSTRAINT either_member_of_work_package_or_project'
      end
    end
  end
end

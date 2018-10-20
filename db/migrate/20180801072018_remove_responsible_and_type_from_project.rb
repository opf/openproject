class RemoveResponsibleAndTypeFromProject < ActiveRecord::Migration[5.1]
  def up
    remove_belongs_to :projects, :responsible
    remove_belongs_to :projects, :work_packages_responsible
    remove_belongs_to :projects, :project_type

    drop_table :project_types
  end

  def down
    # Recreate project type
    Tables::ProjectTypes.create self

    change_table :projects do |t|
      t.belongs_to :responsible, type: :int
      t.belongs_to :work_packages_responsible, type: :int
      t.belongs_to :project_type, type: :int
    end
  end
end

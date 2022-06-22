class DropProjectAssociations < ActiveRecord::Migration[7.0]
  def change
    drop_table :project_associations do |t|
      t.belongs_to :project_a, type: :int
      t.belongs_to :project_b, type: :int

      t.column :description, :text

      t.timestamps null: true
    end
  end
end

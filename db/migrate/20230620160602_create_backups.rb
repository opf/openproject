class CreateBackups < ActiveRecord::Migration[7.0]
  def change
    create_table :backups do |t|
      t.string :comment
      t.integer :size_in_mb
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end

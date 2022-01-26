class CreateStorage < ActiveRecord::Migration[6.1]
  def change
    create_table :storages do |t|
      t.string :provider_type
      t.string :name
      t.references :creator, null: false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end

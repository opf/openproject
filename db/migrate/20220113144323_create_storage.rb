class CreateStorage < ActiveRecord::Migration[6.1]
  def change
    create_table :storages do |t|
      t.string :provider_type
      t.string :name
      t.bigint :creator_id, null: false, foreign_key: true
      t.string :identifier, null: false

      t.timestamps

      t.index :identifier
    end
  end
end

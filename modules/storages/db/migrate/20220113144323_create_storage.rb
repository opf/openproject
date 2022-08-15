class CreateStorage < ActiveRecord::Migration[6.1]
  def change
    create_table :storages do |t|
      t.string :provider_type, null: false
      t.string :name, null: false, index: { unique: true }
      t.string :host, null: false, index: { unique: true }
      t.references :creator, null: false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end

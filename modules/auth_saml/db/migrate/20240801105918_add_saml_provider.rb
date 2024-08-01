class AddSamlProvider < ActiveRecord::Migration[7.1]
  def change
    create_table :saml_providers do |t|
      t.string :display_name, null: false, index: { unique: true }
      t.boolean :available, null: false, default: true
      t.boolean :limit_self_registration, null: false, default: false
      t.jsonb :options, default: {}, null: false
      t.references :creator, null: false, index: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
